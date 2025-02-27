
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_sk, ws.web_site_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_department AS department,
        COUNT(c.c_customer_sk) AS customer_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_department
)
SELECT
    ra.web_site_id,
    ra.total_net_profit,
    cd.department,
    cd.customer_count,
    COALESCE(ra.total_net_profit - (SELECT AVG(total_net_profit) FROM RankedSales), 0) AS profit_difference
FROM
    RankedSales ra
FULL OUTER JOIN
    CustomerDemographics cd ON ra.web_site_sk IS NULL OR cd.customer_count IS NOT NULL
WHERE 
    ra.rank <= 5
ORDER BY 
    ra.total_net_profit DESC, cd.customer_count DESC;
