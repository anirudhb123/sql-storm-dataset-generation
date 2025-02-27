WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    mk.movie_id,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mc.id) AS total_companies,
    AVG(p.info) AS average_person_age,
    DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS keyword_rank
FROM 
    MovieHierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'age')
WHERE 
    mh.level <= 2
GROUP BY 
    mk.movie_id, mh.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    average_person_age NULLS LAST, 
    total_keywords DESC;
