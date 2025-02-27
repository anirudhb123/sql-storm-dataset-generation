WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

NameWithRole AS (
    SELECT 
        n.name AS actor_name,
        ci.movie_id,
        ci.person_role_id,
        COALESCE(rt.role, 'Unknown Role') AS role_name
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name n ON ci.person_id = n.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL
    AND 
        n.name IS NOT NULL
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

MoviesWithHighestActors AS (
    SELECT 
        nm.movie_id,
        COUNT(nm.actor_name) AS actor_count
    FROM 
        NameWithRole nm
    GROUP BY 
        nm.movie_id
    HAVING 
        COUNT(nm.actor_name) > 2
)

SELECT 
    rm.title,
    rm.production_year,
    nm.actor_name,
    nm.role_name,
    COUNT(mc.company_name) AS company_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY COUNT(mc.company_name) DESC) AS company_rank
FROM 
    RankedMovies rm
JOIN 
    NameWithRole nm ON rm.movie_id = nm.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
JOIN 
    MoviesWithHighestActors mha ON rm.movie_id = mha.movie_id
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.title, rm.production_year, nm.actor_name, nm.role_name
ORDER BY 
    rm.production_year DESC, company_count DESC, actor_name;
