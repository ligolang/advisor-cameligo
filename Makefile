ligo_compiler?=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
protocol_opt?=
JSON_OPT?=--michelson-format json
tsc=npx tsc
help:
	@echo  'Usage:'
	@echo  '  all             - Remove generated Michelson files, recompile smart contracts and lauch all tests'
	@echo  '  clean           - Remove generated Michelson files'
	@echo  '  compile         - Compiles smart contract advisor and indice'
	@echo  '  advisor         - Compiles smart contract advisor'
	@echo  '  indice          - Compiles smart contract indice'
	@echo  '  test            - Run integration tests (written in Ligo) and unit tests (written in pytezos)'
	@echo  '  test_ligo       - Run integration tests (written in Ligo)'
	@echo  '  test_pytezos    - Run unit tests (written in pytezos)'
	@echo  '  dry-run         - Simulate execution of entrypoints (with the Ligo compiler)'
	@echo  '  deploy          - Deploy smart contracts advisor & indice (typescript using Taquito)'
	@echo  ''

all: clean compile test

compile: indice advisor

indice: indice.tz indice.json

advisor: advisor.tz advisor.json

indice.tz: src/indice/main.mligo
	@mkdir -p compiled
	@echo "Compiling Indice smart contract to Michelson"
	@$(ligo_compiler) compile contract $^ -e indiceMain $(protocol_opt) > compiled/$@

indice.json: src/indice/main.mligo
	@mkdir -p compiled
	@echo "Compiling Indice smart contract to Michelson in JSON format"
	@$(ligo_compiler) compile contract $^ $(JSON_OPT) -e indiceMain $(protocol_opt) > compiled/$@

advisor.tz: src/advisor/main.mligo
	@mkdir -p compiled
	@echo "Compiling Advisor smart contract to Michelson"
	@$(ligo_compiler) compile contract $^ -e advisorMain $(protocol_opt) > compiled/$@

advisor.json: src/advisor/main.mligo
	@mkdir -p compiled
	@echo "Compiling Advisor smart contract to Michelson in JSON format"
	@$(ligo_compiler) compile contract $^ $(JSON_OPT) -e advisorMain $(protocol_opt) > compiled/$@

clean:
	@echo "Removing Michelson files"
	@rm -f compiled/*.tz compiled/*.json

test: test_ligo test_ligo_2

test_ligo: test/ligo/test.mligo
	@echo "Running integration tests"
	@$(ligo_compiler) run test $^ $(protocol_opt)

test_ligo_2: test/ligo/test2.mligo
	@echo "Running integration tests (fail)"
	@$(ligo_compiler) run test $^ $(protocol_opt)

deploy: node_modules deploy.js

deploy.js:
	@if [ ! -f ./deploy/metadata.json ]; then cp deploy/metadata.json.dist deploy/metadata.json ; fi
	@echo "Running deploy script\n"
	@cd deploy && npm start

node_modules:
	@echo "Installing deploy script dependencies"
	@cd deploy && npm install
	@echo ""

dry-run: dry-run_indice dry-run_advisor

dry-run_advisor: advisor.mligo
#	@echo $(simulateline)
	$(ligo_compiler) compile parameter src/advisor/main.mligo 'ExecuteAlgorithm(unit)' -e advisorMain $(protocol_opt)
	$(ligo_compiler) compile parameter src/advisor/main.mligo 'ChangeAlgorithm(fun(i : int) -> False)' -e advisorMain $(protocol_opt)
	$(ligo_compiler) run dry-run src/advisor/main.mligo  'ExecuteAlgorithm(unit)' '{indiceAddress=("KT1D99kSAsGuLNmT1CAZWx51vgvJpzSQuoZn" : address); algorithm=(fun(i : int) -> if i < 10 then True else False); result=False}' -e advisorMain $(protocol_opt)
	$(ligo_compiler) run dry-run src/advisor/main.mligo  'ChangeAlgorithm(fun(i : int) -> False)' '{indiceAddress=("KT1D99kSAsGuLNmT1CAZWx51vgvJpzSQuoZn" : address); algorithm=(fun(i : int) -> if i < 10 then True else False); result=False}' -e advisorMain $(protocol_opt)

dry-run_indice: indice.mligo
	$(ligo_compiler) compile parameter indice.mligo 'Increment(5)' -e indiceMain $(protocol_opt)
	$(ligo_compiler) compile parameter indice.mligo 'Decrement(5)' -e indiceMain $(protocol_opt)
	$(ligo_compiler) run dry-run indice.mligo  'Increment(5)' '37' -e indiceMain $(protocol_opt)
	$(ligo_compiler) run dry-run indice.mligo  'Decrement(5)' '37' -e indiceMain $(protocol_opt)
