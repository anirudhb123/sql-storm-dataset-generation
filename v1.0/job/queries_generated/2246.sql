WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT COALESCE(c.note, 'no_note')) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mc.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mc.role_name, 'Unknown Role') AS role_name,
    m.rank_per_year,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.movie_id AND mi.note IS NOT NULL) AS info_notes_count
FROM 
    RankedMovies m
LEFT JOIN 
    MovieCast mc ON m.movie_id = mc.movie_id
WHERE 
    m.rank_per_year <= 5
ORDER BY 
    m.production_year DESC, 
    mc.role_count DESC NULLS LAST;
