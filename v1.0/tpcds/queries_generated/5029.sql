
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_state, cd.cd_gender, cd.cd_marital_status
), state_summary AS (
    SELECT 
        ca_state,
        SUM(total_net_profit) AS state_total_net_profit,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(unique_items_purchased) AS avg_items_per_customer
    FROM 
        customer_summary
    GROUP BY 
        ca_state
)
SELECT 
    st.ca_state,
    st.state_total_net_profit,
    st.customer_count,
    st.avg_items_per_customer,
    d.d_year,
    d.d_quarter_seq
FROM 
    state_summary st
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales ws GROUP BY ws_bill_customer_sk)
WHERE 
    st.state_total_net_profit > (SELECT AVG(state_total_net_profit) FROM state_summary)
ORDER BY 
    st.state_total_net_profit DESC;
