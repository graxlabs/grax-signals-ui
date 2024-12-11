#! /usr/bin/env python3
# test via:
# ./bin/inference-cold-leads.py '{"numberofemployees_i": 100, "industry": "Technology", "annualrevenue_f": 1000000, "country": "United States", "state": "CA", "title": "CEO", "department__c": "Executive", "leadsource": "Web", "original_source__c": "Organic Search", "budget__c_f": 50000}'

from fastai.tabular.all import *
import json
import sys
from pathlib import Path

def predict_lead(learn, lead_data):
    """Make prediction for a single lead"""
    try:
        # Convert input data to pandas Series
        input_series = pd.Series(lead_data)

        # Get prediction
        pred_class, pred_idx, probs = learn.predict(input_series)

        return {
            'success': True,
            'prediction': bool(pred_idx.item()),
            'probability': float(probs[1].item()),
            'score': int(float(probs[1].item()) * 100)
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

def main():
    try:
        # Get input data from command line
        input_data = json.loads(sys.argv[1])

        # Get model directory from command line or use default
        model_dir = sys.argv[2] if len(sys.argv) > 2 else '.'

        # Load model
        learn = load_learner('./ml-models/cold-leads-1.pkl')

        # Make prediction
        with learn.no_bar():
          result = predict_lead(learn, input_data)

          # Print result as JSON
          print(json.dumps(result))

    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': str(e)
        }))
        sys.exit(1)

#if __name__ == "__main__":
main()