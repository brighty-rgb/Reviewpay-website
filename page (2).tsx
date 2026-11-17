"use client";

import { FormEvent, useState } from "react";
import { supabase } from "../../lib/supabase";

export default function Register() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");

  async function submit(e: FormEvent) {
    e.preventDefault();
    setMessage("");
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: name } }
    });
    setMessage(error ? error.message :
      "Registration received. Verify your email if prompted, then wait for administrator approval.");
  }

  return <main style={{maxWidth: 440, margin: "50px auto", padding: 24, fontFamily: "Arial"}}>
    <h1>Create a ReviewPay account</h1>
    <form onSubmit={submit}>
      <p><label>Full name<br/><input required value={name} onChange={e=>setName(e.target.value)} /></label></p>
      <p><label>Email<br/><input required type="email" value={email} onChange={e=>setEmail(e.target.value)} /></label></p>
      <p><label>Password (at least 10 characters)<br/><input required minLength={10} type="password" value={password} onChange={e=>setPassword(e.target.value)} /></label></p>
      <button type="submit">Register</button>
    </form>
    <p>{message}</p>
    <a href="/login">Already registered? Log in</a>
  </main>;
}
