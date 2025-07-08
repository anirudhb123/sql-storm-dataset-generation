
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT m.id AS movie_id, 
           m.title,
           1 AS depth
    FROM aka_title m
    WHERE m.id = (SELECT id FROM aka_title WHERE title ILIKE '%Inception%' LIMIT 1)
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title,
           h.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy h ON ml.movie_id = h.movie_id
),
MovieDetails AS (
    
    SELECT at.id AS movie_id,
           at.title,
           at.production_year,
           COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count,
           COALESCE(STRING_AGG(DISTINCT k.keyword), 'No Keywords') AS keywords,
           COALESCE(STRING_AGG(DISTINCT c.kind), 'Unknown Type') AS company_types
    FROM aka_title at
    LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN company_type c ON mc.company_type_id = c.id
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY at.id, at.title, at.production_year
)
SELECT mh.title AS movie_title,
       md.production_year,
       md.company_count,
       md.keywords,
       md.company_types,
       COUNT(ci.id) FILTER (WHERE ci.note IS NOT NULL) AS cast_info_with_notes,
       AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
FROM MovieHierarchy mh
JOIN MovieDetails md ON mh.movie_id = md.movie_id
LEFT JOIN cast_info ci ON md.movie_id = ci.movie_id
WHERE md.production_year BETWEEN 2000 AND 2020
GROUP BY mh.title, md.production_year, md.company_count, md.keywords, md.company_types
ORDER BY md.production_year DESC, mh.title
LIMIT 10;
