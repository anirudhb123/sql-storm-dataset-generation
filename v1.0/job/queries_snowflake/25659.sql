WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM 
        title
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ak.name AS actor_name,
        rt.role AS role,
        cn.name AS company_name
    FROM 
        TopMovies tm
    JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    md.title, 
    md.production_year, 
    md.actor_name, 
    md.role, 
    COUNT(DISTINCT md.company_name) AS company_count
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.actor_name, md.role
HAVING 
    COUNT(DISTINCT md.company_name) > 0
ORDER BY 
    md.production_year DESC, 
    company_count DESC
LIMIT 10;
