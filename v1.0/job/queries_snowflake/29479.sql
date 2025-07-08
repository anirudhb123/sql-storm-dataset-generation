
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
