WITH MovieRoles AS (
    SELECT
        c.movie_id,
        r.role AS role_name,
        COUNT(c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
MoviesWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title
),
HighRatedTitles AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        AVG(r.rating) AS avg_rating
    FROM
        aka_title m
    JOIN
        movie_info mi ON m.id = mi.movie_id
    JOIN
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id IN (SELECT id FROM info_type WHERE info='rating')) r 
        ON m.id = r.movie_id
    WHERE
        m.production_year >= 2000
    GROUP BY 
        m.id
    HAVING 
        AVG(r.rating) > 7
)
SELECT
    m.title AS movie_title,
    mk.keywords,
    mr.role_name,
    mr.actor_count,
    h.avg_rating
FROM
    MoviesWithKeywords mk
JOIN
    MovieRoles mr ON mk.movie_id = mr.movie_id
JOIN
    HighRatedTitles h ON mk.movie_id = h.movie_id
WHERE
    mr.actor_count >= 3
ORDER BY
    h.avg_rating DESC,
    mk.title ASC
LIMIT 10;
