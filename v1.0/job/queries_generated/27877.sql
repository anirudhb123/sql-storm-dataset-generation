WITH MovieCast AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
KeywordMovies AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%drama%'
),
CompanyMovies AS (
    SELECT 
        t.title AS movie_title,
        c.name AS company_name
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
)
SELECT 
    DISTINCT mc.movie_title,
    mc.production_year,
    string_agg(DISTINCT a.actor_name, ', ') AS actors,
    string_agg(DISTINCT km.movie_keyword, ', ') AS keywords,
    string_agg(DISTINCT co.company_name, ', ') AS companies
FROM 
    MovieCast AS mc
LEFT JOIN 
    KeywordMovies AS km ON mc.movie_title = km.movie_title
LEFT JOIN 
    CompanyMovies AS co ON mc.movie_title = co.movie_title
GROUP BY 
    mc.movie_title, mc.production_year
ORDER BY 
    mc.production_year DESC;
