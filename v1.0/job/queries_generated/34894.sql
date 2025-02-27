WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select all movies with their immediate production companies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        c.name AS company_name,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    
    UNION ALL
    
    -- Recursive case: select movie projects linked by company partnerships
    SELECT 
        mh.movie_id,
        mh.title,
        mc.company_id,
        c.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
),
-- Create a summary of movie information and total productions by year
MovieSummary AS (
    SELECT 
        mt.production_year,
        COUNT(DISTINCT mt.id) AS total_movies,
        STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles
    FROM 
        aka_title mt
    GROUP BY 
        mt.production_year
),
-- Incorporate window function to rank movies by production within years
RankedMovies AS (
    SELECT 
        ms.production_year,
        ms.movie_titles,
        ms.total_movies,
        RANK() OVER (ORDER BY ms.total_movies DESC) AS production_rank
    FROM 
        MovieSummary ms
),
-- Gathering information about the cast and roles
CastInfo AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        rt.role AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
-- Final query to put together all relevant information
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.company_name,
    SUM(CASE WHEN rk.production_rank <= 10 THEN 1 ELSE 0 END) AS top_production_count,
    STRING_AGG(DISTINCT ci.actor_name || ' (' || ci.role_type || ')', ', ') AS actors_role
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rk ON mh.movie_id = rk.production_year
LEFT JOIN 
    CastInfo ci ON mh.movie_id = ci.movie_title
GROUP BY 
    mh.movie_id, mh.title, mh.company_name
ORDER BY 
    SUM(CASE WHEN rk.production_rank <= 10 THEN 1 ELSE 0 END) DESC, mh.title;

