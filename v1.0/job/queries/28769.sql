WITH RelevantMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword ILIKE '%action%'
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        COUNT(c.id) AS roles_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.name, c.movie_id
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
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ad.actor_name,
        ad.roles_count,
        mc.company_name,
        mc.company_type
    FROM 
        RelevantMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    ARRAY_AGG(DISTINCT actor_name) AS actors,
    MAX(roles_count) AS highest_roles_count,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS production_companies
FROM 
    CombinedData
GROUP BY 
    movie_id, movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
