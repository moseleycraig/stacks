import Link from "next/link";

export default function Home() {
  return (
    <div style={{ textAlign: "center", padding: "20px" }}>
      <h1>Welcome to the Escrow DApp</h1>
      <p>This is a Bitcoin-powered escrow service using Clarity smart contracts on Stacks.</p>
      
      <Link href="/escrow">
        <button style={{ padding: "10px 20px", fontSize: "16px", cursor: "pointer" }}>
          Go to Escrow Page
        </button>
      </Link>
    </div>
  );
}
