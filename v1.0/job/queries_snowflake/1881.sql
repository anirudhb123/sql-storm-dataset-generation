
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.nr_order) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id, a.name
),
MovieGenres AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT g.keyword, ', ') WITHIN GROUP (ORDER BY g.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mg.genres, 'Unknown') AS genres,
    COALESCE(mc.total_roles, 0) AS role_count
FROM 
    RankedMovies r
LEFT JOIN 
    MovieGenres mg ON r.movie_id = mg.movie_id
LEFT JOIN 
    MovieCast mc ON r.movie_id = mc.movie_id
WHERE 
    r.rn <= 10
ORDER BY 
    r.production_year DESC, 
    COALESCE(mc.total_roles, 0) DESC;
