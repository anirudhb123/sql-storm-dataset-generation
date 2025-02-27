WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS person_role,
        an.name AS actor_name,
        pi.info AS actor_info 
    FROM 
        title t 
    JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    JOIN 
        company_name c ON mc.company_id = c.id 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name an ON ci.person_id = an.person_id 
    JOIN 
        role_type r ON ci.role_id = r.id 
    JOIN 
        person_info pi ON ci.person_id = pi.person_id 
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND r.role ILIKE '%actor%' 
        AND k.keyword LIKE '%adventure%'
),
AggregateKeywords AS (
    SELECT 
        movie_title,
        STRING_AGG(movie_keyword, ', ') AS keywords 
    FROM 
        MovieDetails 
    GROUP BY 
        movie_title
)
SELECT 
    md.movie_title,
    md.production_year,
    ak.keywords,
    COUNT(DISTINCT md.actor_name) AS number_of_actors,
    STRING_AGG(DISTINCT md.actor_info, '; ') AS actor_information,
    STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies
FROM 
    MovieDetails md 
JOIN 
    AggregateKeywords ak ON md.movie_title = ak.movie_title 
GROUP BY 
    md.movie_title, 
    md.production_year, 
    ak.keywords 
ORDER BY 
    md.production_year DESC, 
    number_of_actors DESC;

