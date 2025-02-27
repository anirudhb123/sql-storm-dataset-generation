WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.*
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.actors,
        GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ci.kind) AS company_types
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.actors
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    md.keywords,
    md.company_types
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
