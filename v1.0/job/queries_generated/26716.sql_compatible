
WITH enriched_movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, a.name, c.kind
),
average_keywords AS (
    SELECT 
        AVG(COALESCE(NULLIF(ARRAY_LENGTH(STRING_TO_ARRAY(keywords, ', '), 1), 0), 0)) AS avg_keywords_per_movie
    FROM 
        enriched_movie_data
)
SELECT 
    emd.movie_title,
    emd.production_year,
    emd.actor_name,
    emd.cast_type,
    emd.keywords,
    emd.production_companies_count,
    avgk.avg_keywords_per_movie
FROM 
    enriched_movie_data emd
CROSS JOIN 
    average_keywords avgk
ORDER BY 
    emd.production_year DESC, 
    emd.movie_title;
