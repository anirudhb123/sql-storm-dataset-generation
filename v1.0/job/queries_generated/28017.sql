WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_actors,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_actors,
        mi.info AS genre,
        COALESCE(mo.note, 'N/A') AS movie_note
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    LEFT JOIN 
        movie_info mo ON rm.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'note')
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_actors,
        genre,
        movie_note,
        RANK() OVER (ORDER BY total_actors DESC) AS rank
    FROM 
        MovieInfo
)
SELECT 
    tm.*,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.total_actors, tm.genre, tm.movie_note
ORDER BY 
    tm.rank;
