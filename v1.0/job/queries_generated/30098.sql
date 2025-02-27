WITH RECURSIVE movie_stats AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN role.role = 'lead' THEN 1 ELSE 0 END) AS lead_ratio,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        role_type role ON ci.role_id = role.id
    GROUP BY 
        mt.title, mt.production_year
),
ranking AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        lead_ratio,
        role_count,
        RANK() OVER (PARTITION BY production_year ORDER BY lead_ratio DESC, total_cast DESC) AS rank_in_year
    FROM 
        movie_stats
),
movies_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mk.keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
),
keyword_counts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword) AS num_of_keywords
    FROM 
        movies_with_keywords
    GROUP BY 
        movie_id
)

SELECT 
    r.movie_title,
    r.production_year,
    r.total_cast,
    r.lead_ratio,
    r.role_count,
    COALESCE(kw.num_of_keywords, 0) AS num_of_keywords,
    CASE 
        WHEN r.rank_in_year <= 5 THEN 'Top 5'
        ELSE 'Other' 
    END AS ranking_category
FROM 
    ranking r
LEFT JOIN 
    keyword_counts kw ON kw.movie_id = (SELECT id FROM aka_title WHERE title = r.movie_title LIMIT 1)
WHERE 
    r.production_year >= 2000
    AND r.lead_ratio IS NOT NULL
ORDER BY 
    r.production_year DESC, 
    r.lead_ratio DESC;

