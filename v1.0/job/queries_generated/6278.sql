WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorFilmCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS film_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_id) > 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    afc.actor_name,
    afc.film_count,
    md.company_type,
    STRING_AGG(md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    ActorFilmCount afc ON md.actor_name = afc.actor_name
GROUP BY 
    md.movie_id, md.title, md.production_year, afc.actor_name, afc.film_count, md.company_type
ORDER BY 
    md.production_year DESC, afc.film_count DESC;
