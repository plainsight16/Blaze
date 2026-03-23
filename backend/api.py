from flask import Flask, request, jsonify
from app import is_eligible_for_ajo


app = Flask(__name__)

@app.route("/eligible", methods=["POST"])
def eligible():
    data = request.json
    transaction = data.get("transaction", "").strip() # type: ignore
    contribution_amount = data.get("contribtion_amount", "").strip()

    # if not user_msg:
    #     return jsonify({"response": "Empty message"}), 400
    
    response = is_eligible_for_ajo(transaction, contribution_amount)
    return jsonify({"response": f"{response}"}), 200




if __name__ == "__main__":
    app.run(debug=True)

