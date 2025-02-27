WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS rank_by_length,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY a.id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL
        AND LENGTH(a.title) > 0
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        r.role AS role_name,
        CASE 
            WHEN c.nr_order IS NULL THEN 'Unknown Order'
            ELSE CAST(c.nr_order AS TEXT)
        END AS role_order,
        COUNT(*) OVER (PARTITION BY ak.person_id) AS total_roles
    FROM 
        cast_info c
    INNER JOIN 
        aka_name ak ON c.person_id = ak.person_id
    INNER JOIN 
        aka_title at ON c.movie_id = at.id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithHighCompanyCount AS (
    SELECT 
        a.title,
        a.production_year,
        a.company_count
    FROM 
        RankedMovies a
    WHERE 
        a.company_count > 3
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    ar.actor_name,
    ar.role_name,
    ar.role_order,
    COALESCE(cc.kind, 'Unknown Kind') AS company_type,
    CASE 
        WHEN m.company_count IS NULL THEN 'No Companies'
        ELSE CAST(m.company_count AS TEXT)
    END AS number_of_companies
FROM 
    MoviesWithHighCompanyCount m
LEFT JOIN 
    movie_companies mc ON m.title = mc.movie_id
LEFT JOIN 
    company_type cc ON mc.company_type_id = cc.id
LEFT JOIN 
    ActorRoles ar ON m.title = ar.movie_title
WHERE 
    m.production_year BETWEEN 1990 AND 2020
AND 
    NOT EXISTS (
        SELECT 
            1 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = m.title
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Trivia')
            AND mi.info LIKE '%sequel%'
    )
ORDER BY 
    m.production_year DESC, 
    LENGTH(m.title) DESC, 
    ar.role_order ASC;
