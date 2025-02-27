WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ci.company_name, 'Independent') AS company_name,
        COALESCE(ca.actor_count, 0) AS actor_count
    FROM 
        TopMovies t
    LEFT JOIN 
        CompanyInfo ci ON t.title = ci.movie_id
    LEFT JOIN 
        RankedMovies ca ON t.title = ca.title AND t.production_year = ca.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.actor_count,
    CASE 
        WHEN md.actor_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.title = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    md.title, md.production_year, md.company_name, md.actor_count
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
