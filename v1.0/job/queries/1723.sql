WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    CASE 
        WHEN md.cast_count > 10 THEN 'Blockbuster'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Moderate Success'
        ELSE 'Indie Film'
    END AS success_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
