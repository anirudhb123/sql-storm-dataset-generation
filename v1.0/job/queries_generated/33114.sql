WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id,
        a.name AS actor_name,
        1 AS depth
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    WHERE a.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.person_id, 
        c.movie_id,
        a.name AS actor_name,
        depth + 1
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    JOIN ActorHierarchy ah ON ah.movie_id = c.movie_id 
    WHERE ah.depth < 3 AND a.name IS NOT NULL
),

MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
    FROM aka_title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_list
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),

FinalMetrics AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        cd.total_companies,
        cd.companies_list,
        ah.actor_name,
        ah.depth
    FROM MovieDetails md
    LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN ActorHierarchy ah ON ah.movie_id = md.movie_id
    WHERE cd.total_companies > 0 OR md.total_cast > 5
)

SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    total_companies,
    companies_list,
    MAX(depth) AS max_actor_depth,
    COUNT(DISTINCT actor_name) AS unique_actors
FROM FinalMetrics
GROUP BY 
    movie_id, 
    title, 
    production_year, 
    total_cast, 
    total_companies, 
    companies_list
ORDER BY 
    production_year DESC, unique_actors DESC;
