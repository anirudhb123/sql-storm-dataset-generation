
WITH MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::TEXT AS parent_title,
        0 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(*) OVER (PARTITION BY ak.name ORDER BY mh.production_year) AS movie_count,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COALESCE(ci.note, 'No Role Description') AS role_description
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.production_year >= 2000 
    AND (ak.name ILIKE '%John%' OR ak.name ILIKE '%Doe%')
GROUP BY 
    ak.name, mh.title, mh.production_year, ci.note
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    movie_count DESC, mh.production_year DESC;
