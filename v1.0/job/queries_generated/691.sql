WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
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
        COALESCE(mk.keywords_list, 'No keywords') AS keywords,
        COALESCE(SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS informational_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE movie_id = tm.movie_id))
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
    GROUP BY 
        tm.title, tm.production_year, mk.keywords_list
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.informational_count,
    (CASE 
        WHEN md.informational_count > 0 THEN 'Information Available' 
        ELSE 'No Information' 
    END) AS info_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;
