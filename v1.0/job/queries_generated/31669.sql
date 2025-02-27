WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS level,
        m.production_year
    FROM
        aka_title t
        JOIN movie_companies mc ON t.id = mc.movie_id
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN title m ON t.id = m.id
    WHERE
        kt.kind = 'movie' AND
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.level + 1,
        mh.production_year
    FROM
        movie_hierarchy mh
        JOIN movie_link ml ON mh.movie_id = ml.movie_id
        JOIN title t ON ml.linked_movie_id = t.id
        WHERE
        t.production_year >= 2000
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movies_linked,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    cast_info c 
    JOIN aka_name p ON c.person_id = p.person_id
    LEFT JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
    LEFT JOIN title t ON mh.movie_id = t.id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    actor_name;

-- Additionally, let's find movies produced by companies based in a specific country
SELECT 
    m.title,
    cn.name AS company_name,
    kt.kind AS company_type,
    COUNT(*) AS total_movies
FROM 
    aka_title m
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type kt ON mc.company_type_id = kt.id
WHERE
    cn.country_code = 'USA'
GROUP BY 
    m.title, cn.name, kt.kind
ORDER BY 
    total_movies DESC;
