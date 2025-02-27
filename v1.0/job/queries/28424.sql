
WITH RecursiveMovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        p.info AS actor_info,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        title m
    JOIN
        movie_info mi ON mi.movie_id = m.id
    JOIN
        movie_keyword mk ON mk.movie_id = m.id
    JOIN
        keyword k ON k.id = mk.keyword_id
    JOIN
        complete_cast cc ON cc.movie_id = m.id
    JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN
        aka_name a ON a.person_id = ci.person_id
    JOIN
        person_info p ON p.person_id = a.person_id
    WHERE
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
    GROUP BY
        m.id, m.title, m.production_year, a.name, p.info
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON c.id = mc.company_id
    JOIN
        company_type ct ON ct.id = mc.company_type_id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_name,
    r.actor_info,
    r.keywords,
    ARRAY_AGG(DISTINCT mc.company_name || ' (' || mc.company_type || ')') AS companies_involved
FROM
    RecursiveMovieInfo r
LEFT JOIN
    MovieCompanies mc ON mc.movie_id = r.movie_id
GROUP BY
    r.movie_id, r.title, r.production_year, r.actor_name, r.actor_info, r.keywords
ORDER BY
    r.production_year DESC, r.title;
