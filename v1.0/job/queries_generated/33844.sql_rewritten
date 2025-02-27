WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        episode_of_id,
        season_nr,
        episode_nr,
        1 AS level
    FROM 
        title
    WHERE 
        episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        mh.level + 1
    FROM 
        title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),

CommonCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(ak.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        cc.actors,
        CASE 
            WHEN mh.level > 1 THEN 'Series'
            ELSE 'Standalone'
        END AS movie_type
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CommonCast cc ON mh.movie_id = cc.movie_id
),

FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actors,
        md.movie_type
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
        AND (md.movie_type = 'Series' OR md.cast_count > 5)
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actors,
    ROW_NUMBER() OVER (ORDER BY fm.production_year DESC, fm.title) AS ranking
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;