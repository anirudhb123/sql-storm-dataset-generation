
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS cast_rank
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON mk.movie_id = m.id
    JOIN
        keyword k ON k.id = mk.keyword_id
    JOIN
        cast_info c ON c.movie_id = m.id
    WHERE
        m.production_year >= 2000
      AND
        k.keyword ILIKE '%action%'
),

DetailedCast AS (
    SELECT
        ca.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        m.title AS movie_title,
        m.production_year,
        COALESCE(a.imdb_index, 'N/A') AS actor_imdb_index
    FROM
        RankedMovies rm
    JOIN
        cast_info ca ON ca.movie_id = rm.movie_id
    JOIN
        aka_name a ON a.person_id = ca.person_id
    JOIN
        role_type r ON r.id = ca.role_id
    JOIN
        aka_title m ON m.id = rm.movie_id
    WHERE
        rm.cast_rank <= 3  
)

SELECT
    movie_title,
    production_year,
    LISTAGG(actor_name || ' (' || role_name || ')', ', ') WITHIN GROUP (ORDER BY actor_name) AS top_actors,
    COUNT(actor_name) AS total_actors
FROM
    DetailedCast
GROUP BY
    movie_title,
    production_year
ORDER BY
    production_year DESC,
    movie_title;
