WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS person_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanyTypes AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_type c ON m.company_type_id = c.id
    GROUP BY 
        m.movie_id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(ak.name, 'Unknown Actor') AS actor_name,
    ar.person_role,
    pk.keywords,
    ct.company_types,
    mk.company_type_count,
    CASE 
        WHEN mk.company_type_count > 0 THEN 'Has Companies'
        ELSE 'No Companies' 
    END AS company_status,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = m.movie_id) AS total_complete_cast
FROM 
    RankedMovies m
LEFT JOIN 
    ActorRoles ar ON m.movie_id = ar.movie_id
LEFT JOIN 
    aka_name ak ON ar.person_id = ak.person_id AND ak.name IS NOT NULL
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyTypes ct ON m.movie_id = ct.movie_id
WHERE 
    m.title_rank = 1
    AND (m.production_year > 2000 OR m.production_year IS NULL)
ORDER BY 
    m.production_year DESC, m.title ASC;
