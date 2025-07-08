
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.total_cast,
        mw.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        MoviesWithKeywords mw ON rm.movie_id = mw.movie_id
)
SELECT 
    cmd.movie_id,
    cmd.title,
    cmd.production_year,
    COALESCE(cmd.total_cast, 0) AS total_cast,
    COALESCE(cmd.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN cmd.total_cast IS NULL THEN 'Info Missing'
        WHEN cmd.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_category
FROM 
    CompleteMovieData cmd
WHERE 
    cmd.production_year >= 1980 
    AND (cmd.total_cast IS NULL OR cmd.total_cast > 5)
ORDER BY 
    cmd.production_year DESC, 
    cmd.total_cast DESC
LIMIT 50;
