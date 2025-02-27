WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year 
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast c ON tm.movie_id = c.movie_id
    LEFT JOIN 
        cast_info ci ON c.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.title, tm.production_year
),
MoviesWithInfo AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        COALESCE(mo.info, 'No additional info') AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mo ON md.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot Summary')
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.additional_info,
    CASE 
        WHEN m.cast_count > 5 THEN 'Large Cast'
        WHEN m.cast_count > 0 THEN 'Medium Cast'
        ELSE 'No Cast'
    END AS cast_size_category
FROM 
    MoviesWithInfo m
WHERE 
    m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
