
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast_size <= 5
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        LISTAGG(DISTINCT g.keyword, ', ') WITHIN GROUP (ORDER BY g.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    JOIN 
        TopMovies mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MIN(r.role) AS primary_role,
        MAX(CASE WHEN r.role = 'Lead' THEN c.note ELSE NULL END) AS lead_note
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mg.genres, 'No Genre') AS genres,
    ar.actor_count,
    ar.primary_role,
    CASE 
        WHEN ar.lead_note IS NOT NULL THEN 'Lead Actor Note: ' || ar.lead_note
        ELSE 'No Lead Actor Note'
    END AS lead_actor_note
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.movie_id = mg.movie_id
LEFT JOIN 
    ActorRoles ar ON tm.movie_id = ar.movie_id
WHERE 
    tm.production_year >= 2000 AND
    (tm.title ILIKE '%Adventure%' OR tm.title ILIKE '%Fantasy%')
ORDER BY 
    tm.production_year DESC, 
    ar.actor_count DESC
LIMIT 10;
