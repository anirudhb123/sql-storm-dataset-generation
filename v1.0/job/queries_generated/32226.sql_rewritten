WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year,
        1 AS depth
    FROM title t
    WHERE t.episode_of_id IS NULL  
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM title m
    INNER JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastRoleCounts AS (
    SELECT 
        c.movie_id,
        rt.role AS role_name, 
        COUNT(c.id) AS count_of_actors
    FROM cast_info c
    INNER JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id, rt.role
),
AggregateCompanyData AS (
    SELECT 
        mc.movie_id, 
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS num_of_companies
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title, 
        mh.production_year, 
        COALESCE(CASTR.count_of_actors, 0) AS total_actors,
        COALESCE(AGG.num_of_companies, 0) AS total_companies
    FROM MovieHierarchy mh
    LEFT JOIN CastRoleCounts CASTR ON mh.movie_id = CASTR.movie_id
    LEFT JOIN AggregateCompanyData AGG ON mh.movie_id = AGG.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_actors,
    md.total_companies,
    RANK() OVER (ORDER BY md.total_actors DESC) AS actor_rank,
    RANK() OVER (ORDER BY md.total_companies DESC) AS company_rank
FROM MovieDetails md
WHERE md.production_year >= 2000  
ORDER BY md.production_year DESC, md.movie_title
LIMIT 10;