WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank
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
        movie_rank <= 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cm.company_name,
        cm.company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyMovies cm ON tm.movie_id = cm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    ARRAY_AGG(DISTINCT k.keyword) AS movie_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.production_year IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.company_name
ORDER BY 
    md.production_year DESC, total_actors DESC;
