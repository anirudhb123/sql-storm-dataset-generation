WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS directors,
        GROUP_CONCAT(DISTINCT c.name) AS cast_members,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),

FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.directors,
        md.cast_members,
        md.keywords
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2023
)

SELECT 
    f.movie_title,
    f.production_year,
    f.directors,
    f.cast_members,
    f.keywords
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.movie_title ASC
LIMIT 50;

This SQL query benchmarks string processing by extracting movie details, including titles, production years, directors, cast members, and associated keywords from various tables. It first aggregates the data from `aka_title`, `movie_companies`, `cast_info`, and `keyword` tables, applying appropriate joins and filtering for movies produced between 2000 and 2023. The result is then ordered by production year and limited to 50 entries for better performance evaluation in processing strings.
