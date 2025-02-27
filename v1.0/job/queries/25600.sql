WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.name AS company_name,
        cr.role AS person_role,
        ak.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type cr ON ci.role_id = cr.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
CompanyCount AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT company_name) AS company_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
),
ActorCount AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    MD.movie_title,
    MD.production_year,
    COALESCE(CC.company_count, 0) AS number_of_companies,
    COALESCE(AC.actor_count, 0) AS number_of_actors
FROM 
    MovieDetails MD
LEFT JOIN 
    CompanyCount CC ON MD.movie_title = CC.movie_title
LEFT JOIN 
    ActorCount AC ON MD.movie_title = AC.movie_title
ORDER BY 
    MD.production_year DESC,
    MD.movie_title;
