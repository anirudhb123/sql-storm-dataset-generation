WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ai.person_id
),
TopActors AS (
    SELECT 
        ai.person_id,
        ai.name,
        ar.movie_count,
        ar.roles
    FROM 
        aka_name ai
    JOIN 
        ActorRoles ar ON ai.person_id = ar.person_id
    WHERE 
        ar.movie_count > 3
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    ta.roles,
    mc.company_name,
    mc.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id LIMIT 1)
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, ta.name;
