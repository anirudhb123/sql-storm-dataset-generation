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
        STRING_AGG(cd.actor_name, ', ') AS actor_list
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

This SQL query does the following:

1. **Defines a Recursive CTE (MovieHierarchy)**: This allows us to traverse the hierarchy of movie episodes to their parent titles.

2. **Collects Actor Details (CastDetails)**: This CTE gathers the actor names and their roles, adding a rank based on the order of appearance.

3. **Aggregates Movie Stats (MovieStats)**: This CTE calculates the total number of cast members and a list of actor names for each movie.

4. **Gathers Company Information (CompanyInfo)**: This CTE pulls information about movie companies and their types.

5. **Final Stats (FinalStats)**: This combines the data from previous CTEs, providing a comprehensive view of movie statistics along with associated companies.

6. **Selects Final Results**: The main query filters the movies with more than 5 cast members and orders them by production year and number of cast members, limiting the output to the top 20 entries.
