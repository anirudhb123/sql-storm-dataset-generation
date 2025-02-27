WITH MovieStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ka.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT k.keyword) AS keywords_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS actor_percentage,
        STRING_AGG(DISTINCT ci.note, ', ') AS actor_notes
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, ka.name
),
KeywordStats AS (
    SELECT
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_name,
    ms.production_companies,
    ms.keywords_count,
    ks.keyword,
    ks.movie_count,
    ms.actor_percentage,
    ms.actor_notes
FROM 
    MovieStats ms
JOIN 
    KeywordStats ks ON ms.keywords_count > 0
WHERE 
    ms.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ms.production_year DESC, ms.production_companies DESC, ks.movie_count DESC
LIMIT 50;
