
WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
),
FinalBenchmark AS (
    SELECT 
        tt.title, 
        tt.production_year,
        tt.actor_count,
        kc.keyword_count,
        CASE 
            WHEN tt.actor_count >= 5 THEN 'High'
            WHEN tt.actor_count >= 3 THEN 'Medium'
            ELSE 'Low'
        END AS actor_level,
        LENGTH(tt.title) AS title_length,
        REPLACE(tt.title, ' ', '') AS title_without_spaces
    FROM 
        TopTitles tt 
    LEFT JOIN 
        KeywordCounts kc ON tt.title = (SELECT title FROM title WHERE id = kc.movie_id)
)

SELECT 
    production_year, 
    AVG(actor_count) AS avg_actor_count,
    AVG(keyword_count) AS avg_keyword_count,
    MIN(title_length) AS min_title_length,
    MAX(title_length) AS max_title_length,
    SUM(CASE WHEN actor_level = 'High' THEN 1 ELSE 0 END) AS high_actor_count,
    SUM(CASE WHEN actor_level = 'Medium' THEN 1 ELSE 0 END) AS medium_actor_count,
    SUM(CASE WHEN actor_level = 'Low' THEN 1 ELSE 0 END) AS low_actor_count
FROM 
    FinalBenchmark
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
