import pinataSDK from '@pinata/sdk'
import 'dotenv/config'
import fs from 'fs'
import { PinataPinOptions } from '../node_modules/@pinata/sdk/types/index'
const pinata = new pinataSDK(process.env.PINATA_API_KEY, process.env.PINATA_SERECT_KEY)

interface metaDataTemplate {
    name: string,
    description: string,
    image: string,
    attributes: {
        rare: number
    }
}

const pinataUrisUpload = async () => {
    const tokenUris: string[] = []

    const files = fs.readdirSync('./images/Apes/')
    let rare = 0

    for (let item of files) {
        const readableStreamForFile = fs.createReadStream(`./images/Apes/${item}`)
        const options: PinataPinOptions = {
            pinataMetadata: {
                name: item,
            },
            pinataOptions: {
                cidVersion: 0
            }
        };
        const resIPFS = await pinata.pinFileToIPFS(readableStreamForFile, options)

        const metaData: metaDataTemplate = {
            name: item,
            description: `A mutant ape with a rare value of ${rare}`,
            image: `https://gateway.pinata.cloud/ipfs/${resIPFS.IpfsHash}`,
            attributes: {
                rare: rare
            }
        }

        const resJSON = await pinata.pinJSONToIPFS(metaData)
        tokenUris.push(resJSON.IpfsHash)
        rare++
    }

    return tokenUris
}

pinataUrisUpload()