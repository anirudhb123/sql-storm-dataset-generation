WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT rt.role) AS roles
    FROM
        aka_title AS t
    JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    JOIN
        cast_info AS ci ON t.id = ci.movie_id
    JOIN
        aka_name AS a ON ci.person_id = a.person_id
    JOIN
        role_type AS rt ON ci.role_id = rt.id
    JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM
        MovieDetails
)
SELECT
    movie_title,
    production_year,
    movie_keyword,
    company_names,
    actor_names,
    roles
FROM
    TopMovies
WHERE
    rank <= 10
ORDER BY
    production_year DESC;
