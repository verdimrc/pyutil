!#/usr/bin/env python3

"""Helper code to show SageMaker trained estimator's information."""

import pandas as pd
def get_est_attrs(est):
    """Show information on a fitted estimator.
    
    Usage:
    >>> od_model = sagemaker.estimator.Estimator(...)
    >>> ...
    >>> od_model.fit(...)
    >>> pd.options.display.max_colwidth = -1
    >>> get_est_attrs(od_model)
    """
    d = {'attr': [], 'value': []}

    d['attr'].append('latest_training_job.job_name')
    d['value'].append(est.latest_training_job.job_name)

    d['attr'].append('latest_training_job.name')
    d['value'].append(est.latest_training_job.name)

    attrs = ('base_job_name hyperparam_dict hyperparameters image_name input_mode '
            'metric_definitions model_channel_name model_data model_uri output_path role '
            'tags')
    for i in attrs.split(' '):
        a = getattr(est, i)
        if hasattr(a, '__call__'):
            i = i + '()'
            a = a()
        d['attr'].append(i)
        d['value'].append(a)
    return pd.DataFrame(d)
