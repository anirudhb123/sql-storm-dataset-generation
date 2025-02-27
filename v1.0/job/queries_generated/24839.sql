WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS title_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),

genre_casts AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order,
        k.keyword AS genre
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),

filmography AS (
    SELECT 
        r.title_id,
        r.title,
        COUNT(DISTINCT gc.actor_name) AS num_actors,
        COALESCE(MAX(gc.nr_order), 0) AS max_order,
        MAX(r.production_year) AS latest_year
    FROM 
        ranked_titles r
    LEFT JOIN 
        genre_casts gc ON r.title_id = gc.movie_title
    GROUP BY 
        r.title_id, r.title
),

movie_with_summary AS (
    SELECT 
        f.title,
        f.num_actors,
        f.max_order,
        COALESCE(CASE WHEN COUNT(m.id) > 5 THEN 'Popular' ELSE 'Lesser Known' END, 'Unknown') AS popularity_status
    FROM 
        filmography f
    LEFT JOIN 
        movie_info m ON f.title_id = m.movie_id AND m.note IS NOT NULL
    GROUP BY f.title, f.num_actors, f.max_order
)

SELECT 
    movie.title,
    movie.num_actors,
    movie.max_order,
    movie.popularity_status,
    COALESCE(CHAR_LENGTH(movie.title) - CHAR_LENGTH(REPLACE(movie.title, ' ', '')) + 1, 0) AS word_count,
    CASE 
        WHEN movie.num_actors = 0 THEN 'No Actors'
        WHEN movie.num_actors = 1 THEN 'Solo Act'
        ELSE 'Ensemble Cast'
    END AS cast_description
FROM 
    movie_with_summary movie
WHERE 
    movie.popularity_status <> 'Unknown'
ORDER BY 
    movie.num_actors DESC,
    movie.word_count ASC
LIMIT 10;

This SQL query retrieves information about movie titles, including their popularity status based on actor count, and incorporates multiple complex SQL components, such as Common Table Expressions (CTEs), outer joins, correlated subqueries, window functions, complicated predicates, and string expressions. It showcases the use of NULL logic and edge-case evaluations while providing a potential query for performance benchmarking on the provided database schema.
