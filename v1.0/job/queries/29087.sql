
WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        a.name AS actor_name,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year, a.name, c.name, ct.kind
)

SELECT
    movie_title,
    production_year,
    STRING_AGG(actor_name ORDER BY actor_rank) AS actors,
    COUNT(DISTINCT company_name) AS number_of_companies,
    COUNT(DISTINCT keyword_count) AS unique_keyword_count
FROM
    MovieDetails
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, unique_keyword_count DESC;
