get "/" do
  <<~FORM
    <form action="/" method="POST">
      <label for="who">Who are you?</label>
      <input type="text" name="who" />
      <input type="submit" value="That's me!" />
    </form>
  FORM
end

post "/" do
  <<~POST
    Hello, #{form_data["who"]}
    <pre>
      Form data: #{form_data.inspect}
      Request headers: #{headers.inspect}
  POST
end
