
WITH MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
ActorsWithRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithCompanies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        LISTAGG(DISTINCT co.name, ', ') AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mt.id, mt.title
)
SELECT 
    mwk.movie_title,
    awr.actor_name,
    awr.role_name,
    mwc.companies,
    mwc.company_types,
    mwk.keywords
FROM 
    MoviesWithKeywords mwk
JOIN 
    ActorsWithRoles awr ON mwk.movie_id = awr.movie_id
JOIN 
    MoviesWithCompanies mwc ON mwk.movie_id = mwc.movie_id
WHERE 
    mwk.keywords ILIKE '%action%' 
    AND awr.role_order = 1
ORDER BY 
    mwk.movie_title ASC, awr.actor_name ASC;
