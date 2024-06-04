import { utils } from 'ethers'


export interface networkConfigItem {
    name?: string
    subId?: string 
    keyHash?: string 
    keepersUpdateInterval?: string 
    mintFee?: string 
    callbackGasLimit?: string 
    vrfCoordinatorV2?: string
  }
  
export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig:networkConfigInfo = {
    31337 : {
        name : "localhost",
        keyHash : "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
        subId : '98353627432986741815608655561740765997252129670869197616086304772810959332087',
        callbackGasLimit : '40000',
        mintFee : (utils.parseEther('0.1')).toString()
    }
}

