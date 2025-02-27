WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT m.id) OVER (PARTITION BY a.production_year) AS total_movies_in_year,
        COALESCE(NULLIF(a.title, ''), 'Unknown Title') AS safe_title
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL
)
, MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT mi.info SEPARATOR ', ') AS additional_info
    FROM 
        RankedMovies rm
    JOIN 
        title m ON rm.movie_title = m.title AND rm.production_year = m.production_year
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title
)
, CastInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order IS NOT NULL
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.additional_info,
    ci.actor_name,
    ci.actor_rank,
    rm.total_movies_in_year,
    CASE 
        WHEN ci.actor_rank = 1 THEN 'Lead Actor' 
        ELSE 'Supporting Actor' 
    END AS role_category,
    CASE 
        WHEN ci.actor_name IS NULL THEN 'No Actor Info' 
        ELSE ci.actor_name 
    END AS finalized_actor_name 
FROM 
    MovieInfo mi
LEFT JOIN 
    CastInfo ci ON mi.movie_id = ci.movie_id
LEFT JOIN 
    RankedMovies rm ON mi.title = rm.movie_title AND mi.production_year = rm.production_year
WHERE 
    (rm.year_rank <= 5 OR rm.total_movies_in_year > 50)
    AND (mi.additional_info IS NOT NULL OR ci.actor_name IS NOT NULL)
ORDER BY 
    mi.movie_id, ci.actor_rank NULLS LAST;
