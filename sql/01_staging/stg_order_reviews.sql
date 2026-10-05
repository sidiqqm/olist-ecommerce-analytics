create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_order_reviews` as

select
    review_id,
    order_id,
    cast(review_score as INT64) as review_score,
    coalesce(trim(review_comment_title), '') as review_comment_title,
    coalesce(trim(review_comment_message), '') as review_comment_message,
    cast(review_creation_date as TIMESTAMP) as review_creation_date,
    cast(review_answer_timestamp as TIMESTAMP) as review_answer_timestamp
from `olist-ecommerce-analytics-1.olist_raw.raw_order_reviews`