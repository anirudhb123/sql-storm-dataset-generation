WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT movie_id, title, production_year
    FROM RankedMovies
    WHERE year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS companies,
        COUNT(DISTINCT mki.keyword_id) AS keyword_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
        mg.kind_id AS genre_id
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mki ON tm.movie_id = mki.movie_id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_title mg ON tm.movie_id = mg.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, mg.kind_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.companies,
    md.keyword_count,
    md.cast_count,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(gt.kind, 'Unknown Genre') AS genre
FROM 
    MovieDetails md
LEFT JOIN 
    kind_type gt ON md.genre_id = gt.id
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
