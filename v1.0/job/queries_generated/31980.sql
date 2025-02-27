WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        mc.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title m ON mc.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        ct.kind AS role,
        mh.title AS movie_title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY mh.production_year DESC) AS rn
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_hierarchy mh ON c.movie_id = mh.movie_id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
),
filtered_cast AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        role
    FROM 
        cast_details
    WHERE 
        rn <= 5
    ORDER BY 
        production_year DESC
)
SELECT
    f.actor_name,
    f.movie_title,
    f.production_year,
    COALESCE(f.role, 'Unknown Role') AS role,
    COUNT(*) OVER (PARTITION BY f.actor_name) AS total_movies,
    STRING_AGG(DISTINCT CONCAT(cd.name, '(', cd.country_code, ')'), ', ') AS companies
FROM 
    filtered_cast f
LEFT JOIN 
    movie_companies mc ON f.movie_title = mc.movie_id
LEFT JOIN 
    company_name cd ON mc.company_id = cd.imdb_id
WHERE 
    f.production_year BETWEEN 2010 AND 2020
GROUP BY 
    f.actor_name, f.movie_title, f.production_year, f.role
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    f.production_year DESC, f.actor_name;
