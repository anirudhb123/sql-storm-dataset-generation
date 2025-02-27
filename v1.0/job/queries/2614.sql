WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE 
            WHEN it.info = 'summary' THEN mi.info 
            ELSE NULL 
        END, ' ') AS summary_info,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.actor_name,
    mi.summary_info,
    mi.info_type_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id AND mc.actor_rank <= 3
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_in_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_id;
