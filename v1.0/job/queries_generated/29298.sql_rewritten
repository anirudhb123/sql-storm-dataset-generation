WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        c.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS actor_rank
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    WHERE
        a.production_year >= 2000
)
SELECT 
    rm.title,
    rm.production_year,
    STRING_AGG(rm.actor_name, ', ' ORDER BY rm.actor_rank) AS actor_names,
    COUNT(DISTINCT cct.kind) AS unique_cast_types
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.person_id = ci.person_id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
GROUP BY 
    rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.title;