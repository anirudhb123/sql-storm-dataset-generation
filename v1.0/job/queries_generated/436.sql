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
        a.name AS actor_name,
        COUNT(DISTINCT c.role_id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MostPopularMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(a.total_roles, 0) AS actor_count,
        COALESCE(c.total_companies, 0) AS company_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorRoles a ON r.movie_id = a.movie_id
    LEFT JOIN 
        CompanyStats c ON r.movie_id = c.movie_id
    WHERE 
        (a.total_roles > 2 OR c.total_companies > 1)
)
SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.company_count,
    CASE 
        WHEN m.actor_count > 5 THEN 'Blockbuster'
        WHEN m.company_count > 3 THEN 'Major Production'
        ELSE 'Indie/Unknown'
    END AS classification
FROM 
    MostPopularMovies m
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, m.actor_count DESC;
