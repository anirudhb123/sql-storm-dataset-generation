WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        ep.id,
        ep.title,
        ep.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title ep
    JOIN 
        MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT a.id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CompanyCounts cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        ActorCounts ac ON mh.movie_id = ac.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_count,
    md.actor_count,
    CASE 
        WHEN md.actor_count > 10 THEN 'Popular'
        WHEN md.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS ranking
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
