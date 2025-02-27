
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, c.name, a.name
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_id) > 1
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT ac.actor_name, ', ') AS actors,
    md.company_name,
    md.keywords,
    ac.movie_count
FROM 
    MovieDetails md
JOIN 
    ActorCount ac ON md.actor_name = ac.actor_name
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_name, md.keywords, ac.movie_count
ORDER BY 
    md.production_year DESC, ac.movie_count DESC;
