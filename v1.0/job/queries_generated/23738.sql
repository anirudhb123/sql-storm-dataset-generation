WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        tt.title,
        tt.production_year,
        mh.level + 1
    FROM movie_link mt
    JOIN title tt ON mt.linked_movie_id = tt.id
    JOIN MovieHierarchy mh ON mh.movie_id = mt.movie_id
)
, ActorInfo AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(ci.id) AS movie_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS movies
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN title tt ON ci.movie_id = tt.id
    WHERE ak.name IS NOT NULL
    GROUP BY ak.name
)
, KeywordInfo AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    a.actor_name,
    a.movie_count,
    k.keyword,
    k.keyword_rank
FROM MovieHierarchy mh
LEFT JOIN ActorInfo a ON mh.movie_id = a.movie_count
LEFT JOIN KeywordInfo k ON mh.movie_id = k.movie_id
WHERE (k.keyword IS NULL OR k.keyword LIKE 'A%')
  AND (mh.production_year IS NOT NULL AND mh.production_year <> 2023)
ORDER BY mh.production_year DESC, a.movie_count DESC, k.keyword_rank
LIMIT 50
OFFSET 10;
