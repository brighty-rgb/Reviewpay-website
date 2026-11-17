"use client";

import { FormEvent, useState } from "react";
import { supabase } from "../../lib/supabase";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");

  async function submit(e: FormEvent) {
    e.preventDefault();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setMessage(error ? error.message : "Login successful. Next, route the authenticated user to the member or admin dashboard after checking their profile status and role on the server.");
  }

  return <main style={{maxWidth: 440, margin: "50px auto", padding: 24, fontFamily: "Arial"}}>
    <h1>ReviewPay login</h1>
    <form onSubmit={submit}>
      <p><label>Email<br/><input required type="email" value={email} onChange={e=>setEmail(e.target.value)} /></label></p>
      <p><label>Password<br/><input required type="password" value={password} onChange={e=>setPassword(e.target.value)} /></label></p>
      <button type="submit">Log in</button>
    </form>
    <p>{message}</p>
    <a href="/register">Create an account</a>
  </main>;
}
