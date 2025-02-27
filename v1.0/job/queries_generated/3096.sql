WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieCompany AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COALESCE(MAX(m.info), 'No Info') AS additional_info
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name co ON mc.company_id = co.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    ar.name AS actor_name,
    ar.role,
    ar.role_count,
    mc.company_name,
    mc.company_type,
    mc.additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieCompany mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.title_rank <= 5 
    AND (ar.role_count > 1 OR ar.role IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
