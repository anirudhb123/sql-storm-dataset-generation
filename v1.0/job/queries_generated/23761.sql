WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS actor_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(i.info, 'N/A') AS movie_info, 
        CASE 
            WHEN i.info IS NULL THEN TRUE 
            ELSE FALSE 
        END AS is_info_null
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx i ON m.movie_id = i.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    a.actor_count,
    a.actor_roles,
    info.movie_info,
    info.is_info_null,
    CASE 
        WHEN a.actor_count > 10 THEN 'Large Cast'
        WHEN a.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN m.production_year IN (SELECT DISTINCT production_year FROM RankedMovies WHERE title_rank = 1) 
        THEN 'First Title of Year'
        ELSE 'Not First Title of Year'
    END AS title_position,
    CASE 
        WHEN EXISTS(SELECT 1 
                    FROM movie_keyword mk 
                    WHERE mk.movie_id = m.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Comedy%')) 
        THEN 'Comedy'
        ELSE 'Non-Comedy'
    END AS genre_indicator
FROM 
    RankedMovies m
LEFT JOIN 
    ActorRoleCount a ON m.movie_id = a.movie_id
LEFT JOIN 
    MovieInfo info ON m.movie_id = info.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2020 
    AND (info.is_info_null = FALSE OR a.actor_count >= 3)
ORDER BY 
    m.production_year DESC, a.actor_count DESC;
