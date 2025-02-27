WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN r.role LIKE '%Lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    a.movie_count,
    a.lead_roles,
    COALESCE(cmc.company_count, 0) AS company_count,
    CASE 
        WHEN a.movie_count > 5 AND cmc.company_count IS NULL THEN 'More than 5 movies without companies'
        WHEN a.lead_roles > 0 THEN 'Has lead roles'
        ELSE 'Other'
    END AS actor_status,
    (SELECT 
        ARRAY_AGG(DISTINCT kn.keyword) 
    FROM 
        movie_keyword mk
    JOIN 
        keyword kn ON mk.keyword_id = kn.id
    WHERE 
        mk.movie_id = m.movie_id) AS keywords
FROM 
    RankedMovies m
LEFT JOIN 
    ActorRoleCounts a ON m.movie_id = a.person_id
LEFT JOIN 
    CompanyMovieCount cmc ON m.movie_id = cmc.movie_id
WHERE 
    m.rank <= 10
ORDER BY 
    m.production_year DESC, actor_status, m.title;
