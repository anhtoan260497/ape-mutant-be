import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const BASE_FEE = "250000000000000000" // 0.25 is this the premium in LINK?
const GAS_PRICE_LINK = 1e9 // link per gas, is this the gas lane? // 0.000000001 LINK per gas

const VrfCoordinatorV2MockDeploy:DeployFunction = async (hre:HardhatRuntimeEnvironment) => {
    const {deployments, getNamedAccounts} = hre
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = hre.network.config.chainId

    if(chainId !== 31337) return
    
    log('------------------------------------')
    log('Deploying VRF Coordinator...')

    const VrfCoordinatorV2Mock = await deploy("VRFCoordinatorV2Mock", {
        from: deployer,
        args: [BASE_FEE, GAS_PRICE_LINK],
        log: true
    })

    log('VRF Coordinator deployed to:', VrfCoordinatorV2Mock.address)
}

export default VrfCoordinatorV2MockDeploy

VrfCoordinatorV2MockDeploy.tags = ['mocks']