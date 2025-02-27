WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
), 

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        COALESCE(ks.keywords, '') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordStats ks ON ks.movie_id = rm.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    md.keyword_count,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC
LIMIT 10;