WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COALESCE(SUM(mk.keyword) OVER (PARTITION BY a.id), 0) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
), filtered_cast AS (
    SELECT 
        c.id,
        c.movie_id,
        ci.role_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    INNER JOIN 
        complete_cast c ON ci.movie_id = c.movie_id
    GROUP BY 
        c.id, c.movie_id, ci.role_id
    HAVING 
        COUNT(ci.person_id) > 1
), movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(gc.kind, 'Unknown') AS company_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type gc ON mc.company_type_id = gc.id
)
SELECT 
    rm.title,
    rm.production_year,
    fc.actor_count,
    rm.keyword_count,
    CASE 
        WHEN fc.actor_count IS NULL THEN 'No Cast'
        ELSE 'Actors Present'
    END AS cast_status
FROM 
    ranked_movies rm
LEFT JOIN 
    filtered_cast fc ON rm.production_year = fc.movie_id
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC
LIMIT 10;
