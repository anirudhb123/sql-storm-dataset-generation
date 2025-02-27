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
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT ckt.keyword, ', ') AS keywords,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info END) AS budget,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY mt.production_year DESC) AS recent_movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword ckt ON mk.keyword_id = ckt.id
LEFT JOIN 
    movie_info mi ON mt.movie_id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND mt.production_year >= 2000
    AND (mc.note IS NULL OR mc.note <> 'N/A')
GROUP BY 
    a.name, mt.movie_title, mt.production_year
ORDER BY 
    recent_movie_rank, production_year DESC;
