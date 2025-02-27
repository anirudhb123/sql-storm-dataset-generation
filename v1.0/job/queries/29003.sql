WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender AS actor_gender,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        m.info AS additional_info
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        name p ON a.person_id = p.imdb_id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        movie_info m ON t.id = m.movie_id
    WHERE
        t.production_year >= 2000
        AND p.gender = 'F'
        AND k.keyword ILIKE '%drama%'
)
SELECT
    movie_title,
    production_year,
    actor_name,
    actor_gender,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    STRING_AGG(DISTINCT additional_info, '; ') AS additional_infos
FROM
    MovieDetails
GROUP BY
    movie_title,
    production_year,
    actor_name,
    actor_gender
ORDER BY
    production_year DESC,
    movie_title;
