WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        t.id AS root_movie_id
    FROM 
        aka_title t
    WHERE 
        t.kind_id = 1  -- Assuming 1 corresponds to a specific movie type (e.g., 'movie')

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(ci.movie_id) AS roles_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS average_role_note_present,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies_distinct,
    DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    ak.name, ak.id, mh.title, mh.production_year
HAVING 
    COUNT(ci.movie_id) > 1 AND 
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0.5
ORDER BY 
    actor_rank, mh.production_year DESC;
