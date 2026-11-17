export default function Home() {
  return (
    <main style={{maxWidth: 760, margin: "60px auto", padding: 24, fontFamily: "Arial"}}>
      <h1>ReviewPay</h1>
      <h2>Earn rewards for honest product research.</h2>
      <p>Join research tasks, submit genuine feedback, and track approved rewards.</p>
      <p><b>Reward:</b> $0.50 per approved task</p>
      <p><b>Withdrawal threshold:</b> $10.00 gross</p>
      <p><b>Withdrawal fee:</b> $1.00, deducted transparently from the requested payout.</p>
      <p><a href="/register">Create member account</a> · <a href="/login">Member login</a></p>
      <small>Incentivized feedback must be disclosed. Do not submit paid reviews as if they were unpaid customer reviews.</small>
    </main>
  );
}
