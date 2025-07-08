
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_with_most_cast,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),

ActorsWithRoles AS (
    SELECT
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        DENSE_RANK() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        role_type r ON c.role_id = r.id
),

MoviesWithRoles AS (
    SELECT
        m.movie_id,
        m.movie_title,
        LISTAGG(CONCAT(a.actor_name, ' (', a.role_name, ')'), ', ') WITHIN GROUP (ORDER BY a.actor_name) AS cast_with_roles
    FROM
        RankedMovies m
    JOIN
        ActorsWithRoles a ON m.movie_id = a.movie_id
    WHERE
        m.cast_count > 0
    GROUP BY
        m.movie_id, m.movie_title
)

SELECT
    m.movie_title,
    m.production_year,
    COALESCE(m.cast_count, 0) AS total_cast,
    COALESCE(m.keyword_count, 0) AS total_keywords,
    CASE
        WHEN m.rank_with_most_cast IS NULL THEN 'No Rank'
        WHEN m.rank_with_most_cast <= 5 THEN 'Top 5'
        ELSE 'Beyond Top 5'
    END AS ranking_category,
    COALESCE(mr.cast_with_roles, 'No Cast') AS detailed_cast
FROM
    RankedMovies m
LEFT JOIN
    MoviesWithRoles mr ON m.movie_id = mr.movie_id
ORDER BY
    m.production_year DESC,
    total_cast DESC
LIMIT 50;
