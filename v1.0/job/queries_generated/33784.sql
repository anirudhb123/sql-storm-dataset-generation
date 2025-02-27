WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL -- Starting with top-level movies

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_movie_info AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_hierarchy mh ON c.movie_id = mh.movie_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        c.person_id
),
industry_stats AS (
    SELECT
        c.company_id,
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        AVG(m.production_year) AS avg_production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        c.company_id, c.name
),
result_set AS (
    SELECT 
        actor_info.person_id,
        actor_info.total_movies,
        actor_info.actor_names,
        industry_stats.company_name,
        industry_stats.total_movies AS company_movies,
        industry_stats.avg_production_year
    FROM 
        actor_movie_info actor_info
    LEFT JOIN 
        movie_companies mc ON mc.movie_id IN (
            SELECT movie_id FROM cast_info WHERE person_id = actor_info.person_id
        )
    LEFT JOIN 
        industry_stats ON mc.company_id = industry_stats.company_id
)

SELECT 
    COALESCE(r.actor_names, 'Unknown Actor') AS actor_names,
    COALESCE(r.total_movies, 0) AS total_actor_movies,
    COALESCE(r.company_name, 'Independent') AS production_company,
    COALESCE(r.company_movies, 0) AS total_movies_by_company,
    COALESCE(r.avg_production_year, 0) AS avg_year_of_production
FROM 
    result_set r
WHERE 
    r.total_actor_movies > 0
ORDER BY 
    r.total_actor_movies DESC
LIMIT 10;
