WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.phonetic_code, 
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id, 
        e.title, 
        e.production_year, 
        e.phonetic_code, 
        mh.level + 1
    FROM 
        aka_title AS e
    JOIN 
        movie_hierarchy AS mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    p.id AS person_id,
    ak.name AS aka_name,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT ci.role_id) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(mc.company_count, 0) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY title.production_year DESC) AS rn
FROM 
    aka_name AS ak
JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy AS title ON ci.movie_id = title.movie_id
LEFT JOIN (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies AS mc
    GROUP BY 
        mc.movie_id
) AS mc ON title.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword AS mk ON title.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    name AS p ON ak.person_id = p.imdb_id
WHERE 
    title.production_year >= 2000
    AND ak.name IS NOT NULL
    AND ak.name <> ''
GROUP BY 
    p.id, ak.name, title.title, title.production_year, mc.company_count
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    title.production_year DESC, p.id;

