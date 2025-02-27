
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_review_date,
        cd.cd_gender,
        cd.cd_marital_status,
        REPLACE(c.c_email_address, '@example.com', '') AS sanitized_email
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON c.c_last_review_date_sk = d.d_date_sk
),
DistinctCities AS (
    SELECT 
        DISTINCT ca_city
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
EmailDomainCounts AS (
    SELECT 
        SUBSTRING_INDEX(sanitized_email, '.', -1) AS email_domain,
        COUNT(*) AS domain_count
    FROM 
        CustomerInfo
    GROUP BY 
        email_domain
),
TopDomains AS (
    SELECT 
        email_domain,
        domain_count,
        ROW_NUMBER() OVER (ORDER BY domain_count DESC) AS domain_rank
    FROM 
        EmailDomainCounts
)
SELECT 
    ci.full_name,
    ci.last_review_date,
    ci.cd_gender,
    ci.cd_marital_status,
    dc.ca_city,
    td.email_domain,
    td.domain_count
FROM 
    CustomerInfo AS ci
JOIN 
    DistinctCities AS dc ON ci.last_review_date <= CURRENT_DATE
JOIN 
    TopDomains AS td ON ci.sanitized_email LIKE CONCAT('%', td.email_domain)
WHERE 
    td.domain_rank <= 5
ORDER BY 
    ci.last_review_date DESC, 
    td.domain_count DESC;
