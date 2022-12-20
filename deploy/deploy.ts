import { InMemorySigner } from "@taquito/signer";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { buf2hex } from "@taquito/utils";
import chalk from "chalk";
import { Spinner } from "cli-spinner";
import * as dotenv from "dotenv";
import advisor from "../compiled/advisor.json";
import indice from "../compiled/indice.json";
import metadata from "./metadata.json";

dotenv.config({ path: __dirname + "/.env" });

const rpcUrl = process.env.RPC_URL;
const pk = process.env.PK || undefined;

const missingEnvVarLog = (name) =>
  console.log(
    chalk.redBright`Missing ` +
      chalk.red.bold.underline(name) +
      chalk.redBright` env var. Please add it in ` +
      chalk.red.bold.underline(`deploy/.env`)
  );

const makeSpinnerOperation = async <T>(
  operation: Promise<T>,
  {
    loadingMessage,
    endMessage,
  }: {
    loadingMessage: string;
    endMessage: string;
  }
): Promise<T> => {
  const spinner = new Spinner(loadingMessage);
  spinner.start();
  const result = await operation;
  spinner.stop();
  console.log("");
  console.log(endMessage);

  return result;
};

if (!pk && !rpcUrl) {
  console.log(
    chalk.redBright`Couldn't find env variables. Have you renamed ` +
      chalk.red.bold.underline`deploy/.env.dist` +
      chalk.redBright` to ` +
      chalk.red.bold.underline(`deploy/.env`)
  );

  process.exit(-1);
}

if (!pk) {
  missingEnvVarLog("PK");
  process.exit(-1);
}

if (!rpcUrl) {
  missingEnvVarLog("RPC_URL");
  process.exit(-1);
}

const Tezos = new TezosToolkit(rpcUrl);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer });

let indice_address = process.env.INDICE_CONTRACT_ADDRESS || undefined;

const indice_initial_value = 4;
const advisor_initial_result = false;

const lambda_algorithm =
  '[{"prim": "PUSH", "args": [{"prim": "int"}, {"int": "10"}]}, {"prim": "SWAP"}, {"prim": "COMPARE"}, {"prim": "LT"}, {"prim": "IF", "args": [    [{"prim": "PUSH", "args": [{"prim": "bool"}, {"prim": "True"}]}],     [{"prim": "PUSH", "args": [{"prim": "bool"}, {"prim": "False"}]}]    ]}]';

async function deploy() {
  let indice_store = indice_initial_value;

  let advisor_store = {
    metadata: MichelsonMap.fromLiteral({
      "": buf2hex(Buffer.from("tezos-storage:contents")),
      contents: buf2hex(Buffer.from(JSON.stringify(metadata))),
    }),
    indiceAddress: indice_address,
    algorithm: JSON.parse(lambda_algorithm),
    result: advisor_initial_result,
  };

  try {
    // Originate an Indice contract
    if (indice_address === undefined) {
      const indice_originated = await makeSpinnerOperation(
        Tezos.contract.originate({
          code: indice,
          storage: indice_store,
        }),
        {
          loadingMessage:
            chalk.yellowBright`Deploying ` +
            chalk.yellow.bold`INDICE` +
            chalk.yellowBright` contract`,
          endMessage: chalk.green`Contract deployed!`,
        }
      );

      const contract = await makeSpinnerOperation(
        indice_originated.contract(),
        {
          loadingMessage:
            chalk.yellowBright`Waiting for ` +
            chalk.yellow.bold`INDICE` +
            chalk.yellowBright` to be confirmed at: ` +
            chalk.yellow.bold(indice_originated.contractAddress),
          endMessage: chalk.green`INDICE confirmed!`,
        }
      );

      indice_address = contract.address;
      advisor_store.indiceAddress = indice_address;
    }

    // Originate a ADVISOR
    const advisor_originated = await makeSpinnerOperation(
      Tezos.contract.originate({
        code: advisor,
        storage: advisor_store,
      }),
      {
        loadingMessage:
          chalk.yellowBright`Deploying ` +
          chalk.yellow.bold`ADVISOR` +
          chalk.yellowBright` contract`,
        endMessage: chalk.green`Contract deployed!`,
      }
    );

    await makeSpinnerOperation(advisor_originated.contract(), {
      loadingMessage:
        chalk.yellowBright`Waiting for ` +
        chalk.yellow.bold`ADVISOR` +
        chalk.yellowBright` to be confirmed at: ` +
        chalk.yellow.bold(advisor_originated.contractAddress),
      endMessage: chalk.green`ADVISOR confirmed!`,
    });
  } catch (error: any) {
    console.log("");
    console.log(chalk.redBright`Error during deployment:`);
    console.log(error);
    return process.exit(1);
  }
}

deploy();
