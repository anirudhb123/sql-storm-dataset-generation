WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    INNER JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%Drama%'
), 

FilteredCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        STRING_AGG(DISTINCT na.name, ', ') AS actor_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name na ON ci.person_id = na.person_id
    WHERE 
        na.name IS NOT NULL AND 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year,
    rm.kind_id,
    COALESCE(fc.num_actors, 0) AS total_actors,
    fc.actor_names,
    CASE 
        WHEN fc.num_actors IS NULL THEN 'No cast data'
        WHEN fc.num_actors < 5 THEN 'Few actors'
        ELSE 'Well cast'
    END AS cast_evaluation
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
WHERE 
    rm.rn <= 3
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC NULLS LAST
LIMIT 10;