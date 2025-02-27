WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS cast_count,
           STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
MoviesWithKeywords AS (
    SELECT mt.id AS movie_id, mt.title,
           COUNT(mk.keyword_id) AS keyword_count,
           STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id
),
FinalResults AS (
    SELECT mh.movie_id, mh.title, mh.production_year,
           COALESCE(cd.cast_count, 0) AS cast_count,
           COALESCE(cd.actor_names, 'No Cast') AS actor_names,
           COALESCE(mk.keyword_count, 0) AS keyword_count,
           COALESCE(mk.keywords, 'No Keywords') AS keywords,
           ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS rn
    FROM MovieHierarchy mh
    LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN MoviesWithKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT *
FROM FinalResults
WHERE cast_count > 3
  AND (keywords != 'No Keywords' OR keywords IS NOT NULL)
ORDER BY production_year DESC, title ASC;
