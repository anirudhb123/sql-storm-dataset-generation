
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword,
    ai.actor_name,
    ai.role_name,
    mc.companies,
    mc.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id AND ai.actor_rank <= 3
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, rm.movie_title;
