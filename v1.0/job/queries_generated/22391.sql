WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season,
        COALESCE(mt.episode_nr, 0) AS episode,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(at.season_nr, 0),
        COALESCE(at.episode_nr, 0),
        mh.depth + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedMovieData AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.season,
        m.episode,
        COUNT(DISTINCT p.id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM MovieHierarchy m
    LEFT JOIN cast_info p ON p.movie_id = m.movie_id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title, m.production_year, m.season, m.episode
),
FilteredMovieData AS (
    SELECT 
        amd.*,
        ROW_NUMBER() OVER (PARTITION BY amd.production_year ORDER BY amd.cast_count DESC) AS rn
    FROM AggregatedMovieData amd
    WHERE 
        AMD.production_year >= 1990 AND 
        (amd.season = 0 OR amd.episode > 0)
)
SELECT 
    fmd.title,
    fmd.production_year,
    fmd.cast_count,
    fmd.company_count,
    CASE 
        WHEN fmd.cast_count IS NULL THEN 'Unknown'
        WHEN fmd.cast_count > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_description,
    fmd.rn
FROM FilteredMovieData fmd
WHERE fmd.rn <= 5
ORDER BY fmd.production_year DESC, fmd.cast_count DESC
LIMIT 50;

This SQL query follows a structured format with a recursive common table expression for movie hierarchy processing. It aggregates cast and company data, applies filtering to focus on relevant movies (post-1990), and provides a user-friendly classification of the cast size, demonstrating complex SQL practices combining multiple advanced features.
