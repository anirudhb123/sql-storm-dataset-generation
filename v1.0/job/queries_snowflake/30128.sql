
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
  
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1,
        h.movie_id AS parent_id
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
), CastDetails AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
), MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.actor_name) AS total_cast,
        LISTAGG(cd.actor_name, ', ') WITHIN GROUP (ORDER BY cd.actor_name) AS actor_list
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalStats AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.actor_list,
        COALESCE(ci.company_name, 'Independent') AS company_name,
        COALESCE(ci.company_type, 'N/A') AS company_type
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyInfo ci ON ms.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    actor_list,
    company_name,
    company_type
FROM 
    FinalStats
WHERE 
    total_cast > 5
ORDER BY 
    production_year DESC, total_cast DESC
LIMIT 20;
