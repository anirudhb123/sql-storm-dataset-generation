WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(NULLIF(t.production_year, 0), NULL) AS production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.linked_movie_id,
        t.title,
        COALESCE(NULLIF(t.production_year, 0), NULL) AS production_year,
        mh.level + 1
    FROM 
        movie_link mt
    JOIN 
        movie_hierarchy mh ON mt.movie_id = mh.movie_id
    JOIN 
        aka_title t ON mt.linked_movie_id = t.id
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS named_roles
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.level <= 2
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, t.title, mh.production_year
ORDER BY 
    production_year DESC, actor_name;

