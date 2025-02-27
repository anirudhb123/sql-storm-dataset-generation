WITH RECURSIVE movie_hierarchy AS (
    -- CTE to find hierarchical movie relationships (e.g., sequels or episodic series)
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        mh.depth + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

-- CTE to aggregate average ratings for each person based on roles
average_role_rating AS (
    SELECT 
        ci.person_id,
        AVG(CASE 
                WHEN ci.role_id IS NOT NULL THEN rtr.role_rating 
                ELSE NULL 
            END) AS avg_role_rating
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rtr ON ci.role_id = rtr.id
    GROUP BY 
        ci.person_id
),

-- CTE to capture the last movie watched by each person
last_watched AS (
    SELECT 
        ci.person_id,
        MAX(m.production_year) AS last_movie_year
    FROM 
        cast_info ci
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        ci.person_id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(COALESCE(arr.avg_role_rating, 0)) AS avg_role_rating,
    COUNT(DISTINCT mh.movie_id) AS sequels_count,
    lw.last_movie_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    average_role_rating arr ON ak.person_id = arr.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    last_watched lw ON ak.person_id = lw.person_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%uncredited%'
GROUP BY 
    ak.name, lw.last_movie_year
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5                    -- Filter actors who acted in more than 5 movies
    AND AVG(COALESCE(arr.avg_role_rating, 0)) > 7.0    -- Select actors with an average role rating greater than 7
ORDER BY 
    total_movies DESC, avg_role_rating DESC;
