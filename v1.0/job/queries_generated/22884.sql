WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY a.id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
popular_movie_info AS (
    SELECT
        m.id AS movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY
        m.id, k.keyword
    HAVING 
        COUNT(*) > 1
),
non_actor_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        CASE 
            WHEN t.production_year < 2010 THEN 'Old'
            ELSE 'New'
        END AS movie_age
    FROM 
        aka_title t
    WHERE 
        t.id NOT IN (SELECT DISTINCT ci.movie_id FROM cast_info ci)
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    r.total_movies,
    pm.keyword,
    npm.movie_age
FROM 
    ranked_movies r
LEFT JOIN 
    popular_movie_info pm ON r.rn = 1 AND r.production_year = pm.movie_id
FULL OUTER JOIN 
    non_actor_movies npm ON r.movie_title = npm.movie_title AND r.production_year = npm.production_year
WHERE 
    (r.total_movies IS NOT NULL AND r.total_movies > 3)
    OR (pm.keyword IS NOT NULL AND npm.movie_age = 'New')
ORDER BY 
    r.production_year DESC, r.actor_name;

-- Additional bizarre use of NULL logic and complicated predicates can be inserted below or combined
WITH RECURSIVE level_info AS (
    SELECT 
        ci.id, 
        ci.movie_id, 
        ci.person_id,
        1 AS level
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IS NULL
    UNION ALL
    SELECT 
        ci.id, 
        ci.movie_id, 
        ci.person_id,
        li.level + 1
    FROM 
        cast_info ci 
    JOIN 
        level_info li ON ci.movie_id = li.movie_id AND ci.person_id <> li.person_id
    WHERE 
        li.level < 5
)
SELECT 
    DISTINCT * 
FROM 
    level_info li
WHERE 
    li.level IS NOT NULL AND (li.level % 2 = 0 OR li.id IN (SELECT id FROM movie_companies WHERE company_type_id IS NULL))
ORDER BY 
    li.level;
