WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_keyword mk ON t.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.title = mc.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_count
FROM 
    MovieDetails md
WHERE 
    md.company_count IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;
