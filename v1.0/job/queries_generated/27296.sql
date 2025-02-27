WITH MovieData AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.md5sum AS actor_md5,
        r.role AS role_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(m.info, 'No additional info') AS movie_info,
        COALESCE(c.name, 'Unknown Company') AS production_company
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1
        )
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.title, t.production_year, ak.name, ak.md5sum, r.role, m.info, c.name
)
SELECT
    movie_title,
    production_year,
    actor_name,
    actor_md5,
    role_type,
    keywords,
    movie_info,
    production_company
FROM
    MovieData
ORDER BY
    production_year DESC, movie_title;
