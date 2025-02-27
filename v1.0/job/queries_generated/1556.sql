WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, r.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    COALESCE(a.role, 'Unknown') AS actor_role,
    COALESCE(c.company_count, 0) AS company_involvement,
    m.production_year,
    a.role_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aliases
FROM 
    RankedMovies m
LEFT JOIN 
    ActorRoles a ON a.person_id = (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = m.movie_id 
        ORDER BY ci.nr_order 
        LIMIT 1
    )
LEFT JOIN 
    MovieCompanies c ON c.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = a.person_id
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL)
    OR m.title LIKE '%Adventure%'
GROUP BY 
    m.movie_id, m.title, a.role, c.company_count, m.production_year, a.role_count
ORDER BY 
    m.production_year DESC, m.title;
