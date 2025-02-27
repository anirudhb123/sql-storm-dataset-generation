WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM title mt
    WHERE mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

RankedCast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),

FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        rc.actor_name,
        rc.cast_rank,
        rc.total_cast,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS movie_rank
    FROM MovieHierarchy mh
    LEFT JOIN RankedCast rc ON mh.movie_id = rc.movie_id
    WHERE rc.cast_rank <= 3 OR rc.cast_rank IS NULL
)

SELECT
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_name, 'No Actors') AS actor_name,
    fm.cast_rank,
    fm.total_cast,
    RANK() OVER (ORDER BY fm.production_year ASC) AS year_rank,
    (SELECT COUNT(*) FROM title t WHERE t.production_year = fm.production_year) AS yearly_movie_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM FilteredMovies fm
LEFT JOIN movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
GROUP BY
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.cast_rank,
    fm.total_cast
HAVING
    COUNT(DISTINCT kw.keyword) > 0
ORDER BY
    fm.production_year ASC, 
    year_rank DESC;
