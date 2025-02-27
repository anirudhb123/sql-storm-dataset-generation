WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS title, 
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND m.production_year IS NOT NULL
), 
MovieCasting AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
FullMovieData AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        COALESCE(mc.cast_count, 0) AS cast_count, 
        COALESCE(mk.keywords, '(no keywords)') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCasting mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    fmd.title,
    fmd.production_year,
    fmd.cast_count,
    fmd.keywords,
    CASE 
        WHEN fmd.cast_count > (SELECT AVG(cast_count) FROM MovieCasting) THEN 'Above Average'
        WHEN fmd.cast_count < (SELECT AVG(cast_count) FROM MovieCasting) THEN 'Below Average'
        ELSE 'Average'
    END AS cast_analysis
FROM 
    FullMovieData fmd
WHERE 
    fmd.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fmd.production_year DESC, 
    fmd.title;

