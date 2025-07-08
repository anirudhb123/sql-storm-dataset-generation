
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
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieCast AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        TopMovies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieDetails AS (
    SELECT 
        mc.movie_id,
        mc.movie_title,
        LISTAGG(mc.actor_name || ' (' || mc.role_name || ')', ', ') WITHIN GROUP (ORDER BY mc.actor_name) AS actors
    FROM 
        MovieCast mc
    GROUP BY 
        mc.movie_id, mc.movie_title
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.actors,
    mi.info AS movie_info
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
ORDER BY 
    md.movie_title;
