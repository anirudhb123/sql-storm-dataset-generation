
WITH CustomerWebVisits AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.web_name,
        w.web_url,
        COUNT(wp.wp_web_page_sk) AS number_of_visits,
        SUM(wp.wp_char_count) AS total_character_count,
        AVG(wp.wp_char_count) AS average_character_count
    FROM 
        customer c
    JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    JOIN 
        web_site w ON wp.wp_web_site_sk = w.web_site_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, w.web_name, w.web_url
),
RankedVisits AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY number_of_visits DESC) AS visit_rank
    FROM 
        CustomerWebVisits
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.web_name,
    c.number_of_visits,
    c.total_character_count,
    c.average_character_count
FROM 
    RankedVisits c
WHERE 
    c.visit_rank <= 5
ORDER BY 
    c.web_name, c.number_of_visits DESC;
