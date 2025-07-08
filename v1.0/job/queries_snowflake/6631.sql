
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ca.movie_id,
        ca.nr_order AS role_order,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    ad.actor_name,
    ad.actor_role,
    mc.company_name,
    mc.company_type,
    kd.keywords
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    KeywordDetails kd ON rm.movie_id = kd.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, ad.role_order;
