WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS genre,
        MAX(CASE WHEN i.info_type_id = 2 THEN i.info END) AS plot_summary
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx i ON m.movie_id = i.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    pm1.name AS actor_name,
    COALESCE(a.movie_count, 0) AS actor_movie_count,
    pm2.name AS co_actor_name,
    COALESCE(amc.movie_count, 0) AS co_actor_movie_count,
    CASE WHEN m.production_year IS NULL THEN 'Unknown Year' ELSE m.production_year::text END AS production_year_str,
    CASE 
        WHEN m.production_year IS NOT NULL AND m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year IS NOT NULL AND m.production_year >= 2000 THEN 'Modern'
        ELSE 'Unknown Era'
    END AS era,
    COALESCE(mi.genre, 'No Genre') AS genre,
    COALESCE(mi.plot_summary, 'No Plot Summary Available') AS plot_summary
FROM 
    RankedMovies m
LEFT JOIN 
    cast_info c1 ON m.movie_id = c1.movie_id
LEFT JOIN 
    aka_name pm1 ON c1.person_id = pm1.person_id
LEFT JOIN 
    ActorMovieCount a ON pm1.person_id = a.person_id
LEFT JOIN 
    cast_info c2 ON m.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
LEFT JOIN 
    aka_name pm2 ON c2.person_id = pm2.person_id
LEFT JOIN 
    ActorMovieCount amc ON pm2.person_id = amc.person_id
LEFT JOIN 
    MovieInfo mi ON m.movie_id = mi.movie_id
WHERE 
    m.rank <= 10 
    AND (pm1.name IS NOT NULL OR pm2.name IS NOT NULL)
ORDER BY 
    m.production_year DESC, m.movie_title;
