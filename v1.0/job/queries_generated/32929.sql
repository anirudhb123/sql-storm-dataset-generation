WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::INTEGER AS parent_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_movies AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM
        cast_info c
    JOIN
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        c.person_id
),
company_movies AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS company_movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM
        movie_companies mc
    JOIN
        aka_title t ON mc.movie_id = t.id
    GROUP BY 
        mc.company_id
),
ranked_actors AS (
    SELECT 
        a.person_id,
        a.movie_count,
        a.titles,
        ROW_NUMBER() OVER (ORDER BY a.movie_count DESC) AS actor_rank
    FROM 
        actor_movies a
),
ranked_companies AS (
    SELECT 
        c.company_id,
        c.company_movies_count,
        c.movies,
        ROW_NUMBER() OVER (ORDER BY c.company_movies_count DESC) AS company_rank
    FROM 
        company_movies c
)
SELECT 
    a.person_id,
    a.movie_count,
    a.titles,
    c.company_id,
    c.company_movies_count,
    c.movies,
    mh.title AS parent_title,
    mh.production_year,
    CASE 
        WHEN a.movie_count IS NULL THEN 'Actor has no movies'
        ELSE 'Actor has movies'
    END AS actor_status,
    CASE 
        WHEN c.company_movies_count IS NULL THEN 'Company has no movies'
        ELSE 'Company has movies'
    END AS company_status
FROM 
    ranked_actors a
FULL OUTER JOIN 
    ranked_companies c ON a.actor_rank = c.company_rank
LEFT JOIN 
    movie_hierarchy mh ON a.movie_count = mh.level
WHERE 
    (a.movie_count IS NOT NULL OR c.company_movies_count IS NOT NULL)
ORDER BY 
    COALESCE(a.movie_count, 0) DESC,
    COALESCE(c.company_movies_count, 0) DESC;
