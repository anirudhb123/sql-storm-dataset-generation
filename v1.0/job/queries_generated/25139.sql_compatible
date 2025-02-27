
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        m.id, m.title, m.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),

CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        COUNT(DISTINCT p.info) AS info_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id, a.name, r.role
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COUNT(DISTINCT cd.actor_name) AS total_actors,
    COALESCE(SUM(cd.info_count), 0) AS total_actor_info,
    STRING_AGG(DISTINCT cd.role_type, ', ') AS roles_played
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    total_actors DESC, total_actor_info DESC;
