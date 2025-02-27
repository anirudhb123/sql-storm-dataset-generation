WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        et.id,
        et.title,
        et.production_year,
        et.kind_id,
        mh.depth + 1 AS depth
    FROM 
        aka_title et
    INNER JOIN 
        aka_title p ON et.episode_of_id = p.id
    INNER JOIN 
        MovieHierarchy mh ON p.id = mh.movie_id
),


CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),


MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        (SELECT STRING_AGG(DISTINCT key.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword key ON mk.keyword_id = key.id 
         WHERE mk.movie_id = mh.movie_id) AS keywords,
        (SELECT STRING_AGG(DISTINCT c.name, ', ') 
         FROM movie_companies mc 
         JOIN company_name c ON mc.company_id = c.id 
         WHERE mc.movie_id = mh.movie_id) AS companies
    FROM 
        MovieHierarchy mh
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    cd.actor_name,
    cd.role,
    cd.actor_rank
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000 
    AND (md.keywords IS NOT NULL OR cd.actor_name IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    cd.actor_rank;