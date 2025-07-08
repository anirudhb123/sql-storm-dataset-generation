
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
    JOIN 
        aka_title t ON e.id = t.id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    mh.level,
    COALESCE(c.name, 'Unknown') AS character_name,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    ARRAY_AGG(DISTINCT CASE WHEN ci.nr_order = 1 THEN p.name END) AS lead_actors
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name c ON c.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    name p ON p.id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, c.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 3 
ORDER BY 
    mh.production_year DESC, mh.level ASC;
