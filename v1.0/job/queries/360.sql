WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rnk
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        total_cast, 
        avg_order 
    FROM 
        RankedMovies 
    WHERE 
        rnk <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.total_cast,
        tm.avg_order,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        tm.movie_title, tm.production_year, tm.total_cast, tm.avg_order
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.avg_order,
    COALESCE(md.cast_names, 'No Cast') AS cast_names
FROM 
    MovieDetails md
ORDER BY 
    md.total_cast DESC, md.production_year ASC
LIMIT 20;
