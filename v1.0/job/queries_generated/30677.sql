WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mt.kind_id,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    JOIN 
        movie_companies mc ON mc.movie_id = m.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind IN ('Distributor', 'Production')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mt.kind_id,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        movie_companies mc ON ml.linked_movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = m.id
)
, MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.depth,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        MovieHierarchy mh
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN 
        cast_info c ON c.movie_id = mh.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.depth
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.depth,
    ms.actor_count,
    ms.actors,
    COALESCE(ri.info, 'No rating') AS rating_info,
    kc.keyword AS keyword,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    MovieStats ms
LEFT JOIN 
    movie_info mi ON mi.movie_id = ms.movie_id 
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id AND it.info = 'rating'
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ms.movie_id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ms.movie_id
WHERE 
    ms.actor_count > 0
GROUP BY 
    ms.movie_id, ms.title, ms.depth, rating_info, kc.keyword
HAVING 
    COUNT(DISTINCT kc.keyword) > 1
ORDER BY 
    ms.depth DESC, ms.title;
