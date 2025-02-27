WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title AS mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT m.id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link AS ml
    JOIN MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN aka_title AS mt ON ml.linked_movie_id = mt.id
    WHERE mh.level < 5  -- constraint to limit recursion depth
),
DistinctActorCounts AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name AS ak
    JOIN cast_info AS ci ON ak.person_id = ci.person_id
    GROUP BY ak.name
),
MoviesWithKeywords AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        STRING_AGG(kw.keyword, '; ') AS keywords
    FROM aka_title AS mt
    LEFT JOIN movie_keyword AS mk ON mt.id = mk.movie_id
    LEFT JOIN keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY mt.id
),
RankedMovies AS (
    SELECT
        mv.movie_id,
        mv.movie_title,
        mv.keywords,
        ROW_NUMBER() OVER (PARTITION BY mv.movie_title ORDER BY COALESCE(NULLIF(mv.keywords, ''), 'No Keywords') DESC) AS rank
    FROM MoviesWithKeywords AS mv
    WHERE mv.keywords IS NOT NULL OR mv.keywords <> ''
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    dac.actor_name,
    dac.movie_count,
    rm.keywords,
    rm.rank
FROM MovieHierarchy AS mh
LEFT JOIN DistinctActorCounts AS dac ON dac.movie_count > 5 
LEFT JOIN RankedMovies AS rm ON mh.movie_id = rm.movie_id
WHERE mh.level = 0
  AND (mh.title LIKE '%Adventure%' OR mh.title IS NULL)  -- unusual condition combining LIKE with NULL
ORDER BY mh.production_year DESC, dac.movie_count DESC
LIMIT 100;
