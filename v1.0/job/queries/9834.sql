
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies,
        STRING_AGG(DISTINCT a.name, ',') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT pi.info, ',') AS info
    FROM 
        aka_name a
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.keywords,
    md.companies,
    ai.actor_name,
    ai.info
FROM 
    MovieDetails md
JOIN 
    ActorInfo ai ON ai.actor_id IN (
        SELECT 
            ca.id
        FROM 
            complete_cast cc
        JOIN 
            cast_info ca ON cc.subject_id = ca.id
        WHERE 
            cc.movie_id = md.movie_id
    )
ORDER BY 
    md.production_year DESC, md.movie_title;
