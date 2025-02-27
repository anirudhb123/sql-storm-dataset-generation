WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id 
)

SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(COUNT(DISTINCT mc.company_id), 0) AS num_companies,
    COUNT(DISTINCT mk.keyword_id) FILTER (WHERE k.keyword IS NOT NULL) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ak.id) DESC) AS rank_by_actors
FROM 
    MovieHierarchy mh
JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = t.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year IS NOT NULL
GROUP BY 
    t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ak.id) > 2
ORDER BY 
    t.production_year DESC, num_companies DESC;

