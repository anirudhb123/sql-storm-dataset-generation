WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies from the title table
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           NULL::integer AS parent_movie_id
    FROM title t
    WHERE t.production_year >= 2000
    UNION ALL
    -- Recursive case: Select related movies based on links
    SELECT ml.linked_movie_id AS movie_id, 
           t.title, 
           t.production_year, 
           mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN title t ON t.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
-- Selecting the final results
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COUNT(dc.person_id) AS distinct_cast_count,
       STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') AS cast_names,
       AVG(mi.info_text_length) AS avg_info_length
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name a ON a.person_id = ci.person_id
LEFT JOIN (
    SELECT movie_id, 
           LENGTH(info) AS info_text_length
    FROM movie_info
    WHERE info IS NOT NULL
) mi ON mi.movie_id = mh.movie_id
LEFT JOIN (
    SELECT movie_id, 
           COUNT(DISTINCT person_id) AS person_id
    FROM cast_info
    GROUP BY movie_id
) dc ON dc.movie_id = mh.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, distinct_cast_count DESC;
