import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import {WalletProvider} from '@suiet/wallet-kit'
import './index.css'
import "@suiet/wallet-kit/style.css";
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    
      <BrowserRouter>
      <WalletProvider>
        <App />
        </WalletProvider>
      </BrowserRouter>

  </StrictMode>,
)
