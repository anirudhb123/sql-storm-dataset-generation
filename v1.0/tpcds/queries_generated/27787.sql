
WITH CombinedUrls AS (
    SELECT 
        wp.wp_web_page_id,
        wp.wp_url,
        LENGTH(wp.wp_url) AS url_length,
        REGEXP_REPLACE(wp.wp_url, 'https?://', '') AS stripped_url,
        LENGTH(REGEXP_REPLACE(wp.wp_url, 'https?://', '')) AS stripped_url_length,
        REPLACE(wp.wp_url, '/', ' ') AS space_replaced_url,
        CHAR_LENGTH(space_replaced_url) - CHAR_LENGTH(REPLACE(space_replaced_url, ' ', '')) + 1 AS word_count
    FROM 
        web_page wp
)

SELECT 
    wp_id.wp_web_page_id,
    COUNT(*) AS total_word_count,
    SUM(wp_id.word_count) AS total_word_count_cumulative,
    AVG(wp_id.url_length) AS avg_url_length,
    AVG(wp_id.stripped_url_length) AS avg_stripped_url_length
FROM 
    CombinedUrls wp_id
JOIN 
    date_dim d ON DATE(d.d_date) = CURRENT_DATE
GROUP BY 
    wp_id.wp_web_page_id
ORDER BY 
    total_word_count DESC
LIMIT 10;
