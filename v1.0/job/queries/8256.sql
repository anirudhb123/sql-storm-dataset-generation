WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title, 
        at.production_year, 
        ak.name AS actor_name, 
        rn.rank AS role_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        (SELECT 
            movie_id, 
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS rank 
         FROM 
            cast_info) rn ON ci.movie_id = rn.movie_id
)

SELECT 
    rt.movie_title, 
    rt.production_year, 
    STRING_AGG(rt.actor_name, ', ') AS actors,
    COUNT(rt.role_rank) AS total_roles
FROM 
    RankedTitles rt
WHERE 
    rt.production_year = 2023
GROUP BY 
    rt.movie_title, 
    rt.production_year
ORDER BY 
    rt.production_year DESC, 
    total_roles DESC;
