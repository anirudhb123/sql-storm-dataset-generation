WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON m.id = cc.movie_id
    LEFT JOIN 
        aka_name AS a ON cc.subject_id = a.person_id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    WHERE 
        m.production_year >= 2000 
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorCount AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT a.person_id) AS actor_count
    FROM 
        complete_cast AS cc
    JOIN 
        aka_name AS a ON cc.subject_id = a.person_id
    INNER JOIN 
        aka_title AS m ON cc.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.companies,
    md.actors,
    ac.actor_count
FROM 
    MovieDetails AS md
JOIN 
    ActorCount AS ac ON md.movie_id = ac.movie_id
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC
LIMIT 50;
