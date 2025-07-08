
WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ci.movie_id
),
MovieInfos AS (
    SELECT 
        mi.movie_id, 
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
MoviesWithInfo AS (
    SELECT 
        t.title, 
        t.production_year, 
        COALESCE(mc.cast_count, 0) AS cast_count, 
        mi.movie_info
    FROM 
        title t
    LEFT JOIN 
        MovieCast mc ON t.id = mc.movie_id
    LEFT JOIN 
        MovieInfos mi ON t.id = mi.movie_id
),
FilteredMovies AS (
    SELECT 
        mwi.title, 
        mwi.production_year, 
        mwi.cast_count, 
        mwi.movie_info, 
        RANK() OVER (ORDER BY mwi.cast_count DESC, mwi.production_year DESC) AS popularity_rank
    FROM 
        MoviesWithInfo mwi
    WHERE 
        mwi.production_year >= 2000
)
SELECT 
    f.title, 
    f.production_year, 
    f.cast_count, 
    f.movie_info
FROM 
    FilteredMovies f
WHERE 
    f.popularity_rank <= 10
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
