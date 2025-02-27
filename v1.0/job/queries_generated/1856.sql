WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name) AS actors,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No actors') AS actors,
    COALESCE(md.keywords, 'No keywords') AS keywords,
    md.company_count
FROM 
    MovieDetails md
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, md.title;
