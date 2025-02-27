WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 10
),
MovieActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(ma.actor_name, ', ') AS actors,
    (SELECT COUNT(DISTINCT mi.info_type_id) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id) AS info_count,
    COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
FROM 
    TopRankedMovies tm
LEFT JOIN 
    MovieActors ma ON tm.movie_id = ma.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(ma.actor_name) > 0
ORDER BY 
    tm.production_year DESC, 
    tm.title;
