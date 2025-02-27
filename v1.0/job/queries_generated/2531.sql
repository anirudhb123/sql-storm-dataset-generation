WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.title, t.production_year
),
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movies_with_cast AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        rm.company_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_counts ac ON rm.id = ac.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.actor_count,
    mwc.company_count,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = mwc.movie_id) AS supporting_actors,
    CASE 
        WHEN mwc.actor_count > 20 THEN 'Large Cast'
        WHEN mwc.actor_count BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    movies_with_cast mwc
WHERE 
    mwc.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    mwc.production_year DESC, 
    mwc.actor_count DESC;
