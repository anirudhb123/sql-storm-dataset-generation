WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id, 
        e.title, 
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
ActorStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT m.production_year ORDER BY m.production_year) AS years_active,
        COUNT(DISTINCT CASE WHEN c.nr_order = 1 THEN c.movie_id END) AS lead_roles
    FROM 
        cast_info c
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        c.person_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(cs.total_movies, 0) AS actor_total_movies,
    COALESCE(cs.lead_roles, 0) AS actor_lead_roles,
    cm.companies_involved
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorStats cs ON cs.person_id IN (
        SELECT 
            person_id 
        FROM 
            cast_info c
        WHERE 
            c.movie_id = mh.movie_id
    )
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = mh.movie_id
WHERE 
    mh.level <= 2
ORDER BY 
    mh.level, mh.title;

-- Additional filtering can be applied based on specific criteria, such as production year, genre, etc.
