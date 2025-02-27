WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(aka.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mi.info_id) AS info_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(DISTINCT COALESCE(yi.rating, 0)) AS average_rating
FROM MovieHierarchy mh
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name aka ON aka.person_id = ci.person_id
LEFT JOIN movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN (
    SELECT 
        movie_id, 
        AVG(rating) AS rating
    FROM reviews
    GROUP BY movie_id
) yi ON yi.movie_id = mh.movie_id
LEFT JOIN complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN (SELECT 
               movie_id, 
               COUNT(*) AS total_cast 
           FROM cast_info 
           GROUP BY movie_id
           HAVING COUNT(*) > 3) c ON c.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, aka.name
ORDER BY 
    mh.production_year DESC, mh.level, average_rating DESC;
