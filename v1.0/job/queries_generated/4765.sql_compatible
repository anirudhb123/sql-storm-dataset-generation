
WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM title m
    WHERE m.production_year >= 2000
      AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieDetails AS (
    SELECT
        ht.title AS title,
        ht.production_year,
        COALESCE(SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM title ht
    LEFT JOIN movie_keyword mk ON ht.id = mk.movie_id
    LEFT JOIN cast_info ci ON ht.id = ci.movie_id
    LEFT JOIN aka_title akt ON ht.id = akt.movie_id
    LEFT JOIN aka_name ak ON akt.id = ak.id
    WHERE ht.production_year >= 2000
    GROUP BY ht.id, ht.title, ht.production_year
)
SELECT
    md.title,
    md.production_year,
    md.keyword_count,
    md.cast_count,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC, md.keyword_count DESC) AS row_num
FROM MovieDetails md
JOIN MovieHierarchy mh ON md.title = mh.title
WHERE mh.level <= 2
  AND md.cast_count > 0
ORDER BY md.production_year DESC, md.cast_count DESC;
