create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_order_reviews` as 

with metrics as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_creation_date,
        review_answer_timestamp,

        case
            when nullif(trim(review_comment_message), '') is not null
                then true
            else false
        end as has_comment,

        case
            when review_score between 1 and 5 then true
            else false
        end as is_valid_score,

        case
            when review_score > 3 then 'Positive'
            when review_score = 3 then 'Neutral'
            when review_score < 3 then 'Negative'
            else null
        end as review_sentiment,

        case
            when review_score = 5 then '5 - Excellent'
            when review_score = 4 then '4 - Good'
            when review_score = 3 then '3 - Average'
            when review_score = 2 then '2 - Poor'
            when review_score = 1 then '1 - Terrible'
            else null
        end as review_score_label,

        case
            when review_answer_timestamp is not null
                and review_creation_date is not null
                then timestamp_diff(
                    review_answer_timestamp,
                    review_creation_date,
                    minute
                )
            else null
        end as minutes_to_respond,

        review_answer_timestamp is not null as has_responded

    from `olist-ecommerce-analytics-1.olist_staging.stg_order_reviews`
)

select * from metrics
where is_valid_score = true