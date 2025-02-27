WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    akn.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    AVG(mk_count) AS average_keywords,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 2 THEN 'Multiple Companies'
        ELSE 'Single Company or No Company'
    END AS company_association,
    ROW_NUMBER() OVER (PARTITION BY akn.id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(DISTINCT keyword_id) AS mk_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
) mk ON at.id = mk.movie_id
WHERE 
    akn.name IS NOT NULL
GROUP BY 
    akn.id, at.title
HAVING 
    AVG(mk_count) > 1
ORDER BY 
    actor_name, movie_title;
