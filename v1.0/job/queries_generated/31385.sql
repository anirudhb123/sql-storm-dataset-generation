WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM MovieHierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    HAVING COUNT(DISTINCT c.person_id) > 2
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Cast') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM FilteredMovies f
    LEFT JOIN cast_info ci ON f.movie_id = ci.movie_id
    LEFT JOIN aka_name cn ON ci.person_id = cn.person_id
    LEFT JOIN movie_keyword mk ON f.movie_id = mk.movie_id
    GROUP BY f.title, f.production_year
)

SELECT 
    md.title,
    md.production_year,
    md.cast_names,
    md.keyword_count,
    RANK() OVER (ORDER BY md.keyword_count DESC) AS rank_by_keywords
FROM MovieDetails md
WHERE md.keyword_count > 0
ORDER BY rank_by_keywords, md.production_year DESC;
