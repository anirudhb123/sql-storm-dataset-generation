WITH recursive title_hierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        CAST(NULL AS integer) AS parent_title_id,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL

    UNION ALL

    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        th.title_id AS parent_title_id,
        th.level + 1
    FROM title t
    JOIN title_hierarchy th ON t.episode_of_id = th.title_id
),
director_movies AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_directors
    FROM cast_info ci
    INNER JOIN role_type rt ON ci.role_id = rt.id
    WHERE rt.role LIKE 'Director%'
    GROUP BY ci.movie_id
),
movies_with_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
title_info AS (
    SELECT
        tt.title_id,
        tt.title,
        tt.production_year,
        COALESCE(dm.total_directors, 0) AS director_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT cc.id) AS complete_cast_count
    FROM title_hierarchy tt
    LEFT JOIN director_movies dm ON tt.title_id = dm.movie_id
    LEFT JOIN movies_with_keywords mk ON tt.title_id = mk.movie_id
    LEFT JOIN complete_cast cc ON tt.title_id = cc.movie_id
    GROUP BY tt.title_id, tt.title, tt.production_year, dm.total_directors, mk.keywords
)
SELECT
    ti.title,
    ti.production_year,
    ti.director_count,
    ti.keywords,
    CASE
        WHEN ti.complete_cast_count = 0 THEN 'No Cast Available'
        ELSE CAST(ti.complete_cast_count AS text) || ' Cast Members'
    END AS cast_info,
    ROW_NUMBER() OVER (PARTITION BY ti.production_year ORDER BY ti.director_count DESC) AS rank_within_year
FROM title_info ti
WHERE ti.director_count > 1
  AND ti.production_year >= 2000
  AND (ti.keywords LIKE '%action%' OR ti.keywords LIKE '%comedy%')
ORDER BY ti.production_year ASC, ti.director_count DESC
LIMIT 50;
