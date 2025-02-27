WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, actor_aggregate AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_hierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        c.person_id
)
SELECT 
    a.id AS actor_id,
    an.name,
    aa.movie_count,
    aa.movies,
    a.case WHEN aa.movie_count = 0 THEN 'No Movies' ELSE 'Involved in Movies' END AS movie_status,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mi.rating) AS average_rating
FROM 
    aka_name an
JOIN 
    actor_aggregate aa ON an.person_id = aa.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT movie_id FROM movie_hierarchy)
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT movie_id FROM movie_hierarchy) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    cast_info c ON c.person_id = an.person_id
GROUP BY 
    a.id, an.name, aa.movie_count
HAVING 
    COUNT(DISTINCT kc.keyword) > 0 -- only actors with associated keywords
ORDER BY 
    aa.movie_count DESC, average_rating DESC;
