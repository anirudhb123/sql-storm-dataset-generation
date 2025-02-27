WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id, c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        role_type rt ON rt.id = c.role_id
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    rt.title AS Ranked_Title,
    rt.production_year,
    ar.actor_name,
    ar.role,
    md.company_count
FROM 
    RankedTitles rt
JOIN 
    ActorRoles ar ON ar.movie_id = rt.title_id
JOIN 
    MovieDetails md ON md.title = rt.title AND md.production_year = rt.production_year
WHERE 
    ar.role_rank = 1 
ORDER BY 
    rt.production_year DESC, 
    rt.title;

This SQL query performs the following key operations:

1. **RankedTitles**: This CTE ranks movies by title within each production year.
2. **ActorRoles**: This CTE retrieves the names of actors along with their roles for each movie, ranked by the order in which they appeared in the cast.
3. **MovieDetails**: This CTE calculates the total number of production companies associated with each movie.
4. **Final Selection**: The main query joins the three CTEs, filters for the highest-ranked role for each actor, and outputs the results ordered by production year in descending order and by title. 

This query benchmarks string processing by leveraging multiple joins, window functions, and aggregations to extract detailed information from a complex schema.
