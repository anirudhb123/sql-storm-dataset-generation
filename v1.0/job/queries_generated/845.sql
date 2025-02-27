WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
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
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT co.name) AS production_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.title = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names, 'No actors') AS actor_names,
    COALESCE(md.production_companies, 'No companies') AS production_companies
FROM 
    MovieDetails md
UNION ALL
SELECT 
    'Total Movies' AS title,
    NULL AS production_year,
    COUNT(*) AS actor_names,
    NULL AS production_companies
FROM 
    aka_name
WHERE 
    person_id IS NOT NULL
ORDER BY 
    production_year DESC NULLS LAST;
