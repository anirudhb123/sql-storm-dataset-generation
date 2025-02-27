WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COALESCE(pi.info, 'No Info Available') AS person_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        person_info pi ON mk.keyword_id = pi.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    COUNT(CASE WHEN c.nr_order IS NOT NULL THEN 1 END) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info c ON md.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
GROUP BY 
    md.movie_id, md.title, md.production_year, md.keyword
ORDER BY 
    md.production_year DESC, cast_count DESC;
