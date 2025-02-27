WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_year <= 10
), MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        TopRatedMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        mi.info AS movie_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
),
MovieSummary AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.movie_info,
        md.cast_count,
        md.cast_names,
        COALESCE(NULLIF(CAST(2 * md.cast_count AS TEXT), ''), 'No Cast') AS adjusted_cast_count
    FROM 
        MovieInfo mi
    JOIN 
        MovieDetails md ON mi.movie_id = md.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.movie_info,
    ms.cast_count,
    ms.cast_names,
    ms.adjusted_cast_count,
    CASE 
        WHEN ms.cast_count > 5 THEN 'Popular' 
        ELSE 'Less Popular' 
    END AS popularity_rating
FROM 
    MovieSummary ms
WHERE 
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ms.production_year DESC, 
    ms.cast_count DESC;
