WITH MovieCast AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_actors
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_details,
        MAX(mi.production_year) AS latest_year
    FROM 
        movie_info AS mi
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
),
TopMovies AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.actor_names,
        mc.actor_count,
        mi.info_details,
        RANK() OVER (ORDER BY mc.actor_count DESC) AS actor_rank
    FROM 
        MovieCast AS mc
    JOIN 
        MovieInfo AS mi ON mc.movie_id = mi.movie_id
)
SELECT 
    tm.title,
    tm.actor_names,
    COALESCE(tm.info_details, 'No Information') AS info_details,
    tm.actor_count,
    tm.actor_rank
FROM 
    TopMovies AS tm
WHERE 
    tm.actor_rank <= 10
ORDER BY 
    tm.actor_rank;
