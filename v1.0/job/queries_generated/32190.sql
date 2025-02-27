WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(COUNT(ci.id), 0) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM MovieHierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
    LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
),

FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actor_names,
        md.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rn
    FROM MovieDetails md
    WHERE md.cast_count > 0
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actor_names,
    fm.keywords,
    CASE 
        WHEN fm.cast_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_label
FROM FilteredMovies fm
WHERE fm.rn <= 10
ORDER BY fm.production_year DESC, fm.cast_count DESC;
