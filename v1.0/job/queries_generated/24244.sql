WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY m.id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
CompanyParticipation AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    rm.keyword_count,
    ar.actor_name,
    ar.role_name,
    ar.role_count,
    cp.company_name,
    cp.company_type,
    cp.total_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyParticipation cp ON rm.movie_id = cp.movie_id
WHERE 
    (rm.keyword_count IS NULL OR rm.keyword_count > 2) -- Filter for movies with more than 2 keywords or no keywords
    AND (ar.role_count IS NULL OR ar.role_count > 1) -- Only keep actors with multiple roles or no roles
ORDER BY 
    rm.production_year DESC, 
    rm.rank ASC, 
    ar.actor_name
LIMIT 50;
