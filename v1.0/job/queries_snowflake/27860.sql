
WITH actor_movies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY
        a.id, a.name
),
popular_actors AS (
    SELECT
        am.actor_id,
        am.actor_name,
        am.total_movies,
        am.movie_titles,
        RANK() OVER (ORDER BY am.total_movies DESC) AS rank
    FROM
        actor_movies am
),
selected_movies AS (
    SELECT
        mt.movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        kt.keyword
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword kt ON mk.keyword_id = kt.id
    WHERE
        mt.production_year >= 2000 AND
        kt.keyword LIKE '%action%'  
)
SELECT
    pa.actor_id,
    pa.actor_name,
    pa.total_movies,
    pa.movie_titles,
    sm.movie_id,
    sm.title AS action_movie_title,
    sm.production_year
FROM
    popular_actors pa
JOIN
    selected_movies sm ON pa.movie_titles LIKE '%' || sm.title || '%'
WHERE
    pa.rank <= 10  
ORDER BY
    pa.total_movies DESC, sm.production_year DESC;
