WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        RankedMovies rm ON c.movie_id = rm.id
    GROUP BY 
        c.movie_id
), 
MovieDetails AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        mt.kind AS movie_type, 
        COALESCE(mc.cast_count, 0) AS total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        kind_type mt ON rm.kind_id = mt.id
    LEFT JOIN 
        MovieCast mc ON rm.id = mc.movie_id
)
SELECT 
    md.title, 
    md.production_year, 
    md.movie_type, 
    md.total_cast,
    (SELECT 
        STRING_AGG(DISTINCT k.keyword, ', ')
     FROM 
        movie_keyword mk
     JOIN 
        keyword k ON mk.keyword_id = k.id
     WHERE 
        mk.movie_id = md.movie_id) AS keywords
FROM 
    MovieDetails md
WHERE 
    md.total_cast > 5 
    OR md.movie_type IS NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
