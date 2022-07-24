import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";       




const DEBUG = false;

function Gallery({readContracts, address, balance}) {
     
    const [Qty, setQty] = useState(0);
    const [Ids, setIds] = useState([]);
    const [Qtys, setQtys] = useState([]);
    const [Html, setHtml] = useState([]);

    //const image = useContractReader(readContracts, "Quanta", "renderTokenById", [1])
    //const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
   
    const myRef = useRef();
    useEffect(async () => {
      async function getTokenIds() {
        if(readContracts && readContracts.Quanta && address){
        //const result = useContractReader(readContracts, "Quanta", "GetTokenIdsForAddress", [address])
        const result =  await readContracts.Quanta.GetTokenIdsForAddress(address);
          
        if(result){
          if(DEBUG) console.log("result 0",result[0].toNumber());
          if(DEBUG) console.log("result 1",result[1].split(","));
          if(DEBUG) console.log("result 2",result[2].split(","));

          setQty(result[0])
          var Ids = result[1].split(",")
          
          if(DEBUG) console.log("ids length", Ids.length);
          var html = '';
          for(var i = 0; i < Ids.length; ++i) {
            var tokenId = Ids[i];

            if(DEBUG) console.log("ID::",tokenId);
            if(tokenId > 0) {
              var svg = await readContracts.Quanta.renderTokenById(tokenId);  
              if(svg){
                if(DEBUG)console.log("svg", svg)
                html = html + '<svg width="300" height="300">' + svg + '</svg>'
                 
              }
            }
          }
          if(html) {
            console.log("html", html)
            myRef.current.innerHTML = html 
          }          
        }
      }    
    } 
    getTokenIds();
    },[readContracts, balance]);



    return (
    <div>
        <div ref={myRef} />

    </div>
    );
}

export default Gallery;