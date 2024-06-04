import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { networkConfig } from '../helper-network-config';
import pinataUrisUpload from "../scripts/pinata";

const BYMADeploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = hre.network.config.chainId

    const args: any = [
        networkConfig[chainId!].mintFee!,
        networkConfig[chainId!].keyHash!,
        networkConfig[chainId!].callbackGasLimit!,
        networkConfig[chainId!].subId!,
    ]
    console.log('upload pinata')

    const tokenUris = await pinataUrisUpload()
    args.push(tokenUris)

    console.log('deploying BoreYatchMutantApe...')

    const BoreYatchMutantApe = await deploy("BoreYatchMutantApe", {
        from: deployer,
        args,
        log: true
    })


    log(`BoreYatchMutantApe deployed to: ${BoreYatchMutantApe.address}`)
}

export default BYMADeploy
