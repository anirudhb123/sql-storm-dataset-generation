WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Top-level movies
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
ActorPerformance AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        MIN(t.production_year) AS first_appearance,
        MAX(t.production_year) AS last_appearance
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        a.name
),
MovieCompanyDetails AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.title, c.name, ct.kind
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.level,
    a.name AS actor_name,
    ap.movies_count,
    ap.first_appearance,
    ap.last_appearance,
    COALESCE(mc.company_name, 'No Company') AS company_name,
    COALESCE(mc.company_type, 'Unknown') AS company_type,
    mc.company_count
FROM 
    MovieHierarchy h
LEFT JOIN 
    ActorPerformance ap ON h.movie_id IN (SELECT c.movie_id FROM cast_info c WHERE c.person_id IN (SELECT a.id FROM aka_name a WHERE a.name = ap.name))
LEFT JOIN 
    MovieCompanyDetails mc ON h.title = mc.title
ORDER BY 
    h.production_year DESC, h.level, ap.movies_count DESC;

This SQL query constructs a recursive CTE (`MovieHierarchy`) to establish a hierarchy of movies based on their episodes, followed by an aggregate CTE (`ActorPerformance`) to count movies per actor and track their first and last appearances. Additionally, it gathers details about movie companies in another CTE (`MovieCompanyDetails`). Finally, it combines all this data in the main query while ensuring that NULL values are handled properly using the `COALESCE` function, and orders the results by the production year, hierarchy level, and actor count.
