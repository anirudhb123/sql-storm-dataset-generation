
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.surname_pcode,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, a.name, a.surname_pcode, ct.kind
    ORDER BY 
        t.title 
),

ActorStatistics AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)

SELECT 
    a.actor_name,
    a.total_movies,
    a.first_movie_year,
    a.last_movie_year,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_names, '; ') AS associated_companies
FROM 
    ActorStatistics a
JOIN 
    MovieDetails md ON a.actor_name = md.actor_name
GROUP BY 
    a.actor_name, a.total_movies, a.first_movie_year, a.last_movie_year
ORDER BY 
    a.total_movies DESC;
