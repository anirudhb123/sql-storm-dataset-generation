WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to build a hierarchy of movies
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM
        title t
    WHERE
        t.episode_of_id IS NULL

    UNION ALL

    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM
        title t
    JOIN
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
-- CTE to get cast information and rank roles
RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
-- CTE to gather company information
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, c.name, ct.kind
),
-- Final movie info merging and filtering results
FinalMovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(DISTINCT rc.actor_name, ', ') AS cast_list,
        COALESCE(SUM(cd.total_companies), 0) AS company_count,
        COUNT(DISTINCT mh.episode_of_id) AS total_episodes,
        AVG(CASE WHEN rc.rank = 1 THEN 1 ELSE 0 END) * 100 AS lead_actor_percentage
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RankedCast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        CompanyDetails cd ON mh.movie_id = cd.movie_id
    WHERE 
        mh.production_year >= 2000 -- Filter on production year for recent movies
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

-- Final selection to get results with additional filter criteria, handling NULL logic
SELECT 
    fms.movie_id,
    fms.title,
    fms.production_year,
    fms.cast_list,
    fms.company_count,
    fms.total_episodes,
    fms.lead_actor_percentage
FROM 
    FinalMovieStats fms
WHERE 
    (fms.company_count > 1 OR fms.company_count IS NULL)  -- Include movies with more than 1 company or no company
ORDER BY 
    fms.production_year DESC, 
    fms.lead_actor_percentage DESC; -- Order by newest first and then by lead actor presence

This SQL query aims to provide a comprehensive performance benchmark using multiple advanced SQL constructs including recursive common table expressions (CTEs), window functions, joins, aggregation, and filters. It gathers movies from a hierarchical structure, ranks the cast, gathers company details, and finally compiles a summary while applying various complex filters and logical operations.
