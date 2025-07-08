
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL 

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.depth + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rank
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.depth = 0 
),
bridging_table AS (
    SELECT 
        co.name AS company_name,
        c.movie_id,
        c.role_id
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    WHERE 
        co.country_code = 'USA'
        AND c.nr_order = 1
),
aggregated_cast AS (
    SELECT
        a.movie_id,
        COUNT(DISTINCT a.person_id) AS total_cast
    FROM
        cast_info a
    GROUP BY
        a.movie_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    bc.company_name,
    ac.total_cast,
    CASE 
        WHEN ac.total_cast > 10 THEN 'Large Cast'
        WHEN ac.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(r.role, 'Unknown Role') AS primary_role,
    COALESCE(kw.keyword, 'No Keyword') AS movie_keyword
FROM 
    top_movies t
LEFT JOIN 
    bridging_table bc ON t.movie_id = bc.movie_id
LEFT JOIN 
    aggregated_cast ac ON t.movie_id = ac.movie_id
LEFT JOIN 
    role_type r ON r.id = (SELECT MIN(id) FROM role_type WHERE role_id = bc.role_id LIMIT 1)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.rank <= 3 
GROUP BY 
    t.title,
    t.production_year,
    bc.company_name,
    ac.total_cast,
    r.role,
    kw.keyword
ORDER BY 
    t.production_year DESC,
    t.title;
