WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.title
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.companies,
    COALESCE(NULLIF(SUM(mi.info)::text, ''), 'No Information') AS movie_info
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.title = mi.movie_id
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.title, md.production_year, md.actors, md.companies
ORDER BY 
    md.production_year DESC;
