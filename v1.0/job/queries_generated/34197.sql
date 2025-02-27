WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year IS NOT NULL
  
  UNION ALL
  
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM title t
    JOIN movie_link ml ON t.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, RankedActors AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
)
, MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ra.actor_name, 'No Actors') AS actor_name,
        mh.level,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM MovieHierarchy mh
    LEFT JOIN RankedActors ra ON mh.movie_id = ra.movie_id
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, ra.actor_name, mh.level
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.level,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Popular'
        WHEN md.keyword_count = 0 THEN 'Unresolved'
        ELSE 'Moderate'
    END AS keyword_category
FROM MovieDetails md
WHERE md.production_year BETWEEN 1990 AND 2023
AND md.level <= 2
ORDER BY md.production_year DESC, md.keyword_count DESC;
