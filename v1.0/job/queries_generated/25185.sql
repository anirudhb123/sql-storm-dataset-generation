WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
),
TopTitles AS (
    SELECT
        title_id,
        title,
        production_year
    FROM
        RankedTitles
    WHERE
        title_rank <= 5
),
PersonMovies AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id, a.name
)
SELECT
    tt.title,
    tt.production_year,
    pm.actor_name,
    pm.actor_count
FROM
    TopTitles tt
JOIN
    PersonMovies pm ON tt.title_id = pm.movie_id
ORDER BY
    tt.production_year DESC, 
    LENGTH(tt.title) DESC, 
    pm.actor_count DESC;
