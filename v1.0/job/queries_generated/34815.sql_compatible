
WITH RECURSIVE actor_movies AS (
    SELECT 
        ca.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY t.production_year DESC) AS movie_rank,
        ca.movie_id
    FROM 
        cast_info ca
    JOIN 
        aka_name kn ON ca.person_id = kn.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    WHERE 
        kn.name LIKE 'Johnny%' 
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(mc.id) AS contribution_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    am.person_id,
    k.keywords,
    am.title,
    am.production_year,
    cs.company_name,
    cs.contribution_count,
    COALESCE(cs.contribution_count, 0) AS total_contributions
FROM 
    actor_movies am
LEFT JOIN 
    company_statistics cs ON am.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary k ON am.movie_id = k.movie_id
WHERE 
    am.production_year >= 2000 
ORDER BY 
    am.person_id, am.production_year DESC
LIMIT 100;
