WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        ARRAY_AGG(DISTINCT CONCAT(a.first_name, ' ', a.last_name)) AS actors
    FROM
        title m
    JOIN
        movie_info mi ON m.id = mi.movie_id
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON m.id = mc.movie_id
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        complete_cast cc ON m.id = cc.movie_id
    JOIN
        aka_name a ON cc.subject_id = a.person_id
    JOIN
        role_type r ON cc.role_id = r.id
    WHERE
        m.production_year >= 2000  -- Consider movies produced from the year 2000 onwards
        AND k.keyword IS NOT NULL
        AND co.name IS NOT NULL
        AND a.name IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year, c.kind
)
SELECT
    movie_title,
    production_year,
    keywords,
    companies,
    actors
FROM
    movie_details
ORDER BY
    production_year DESC, 
    movie_title ASC
LIMIT 100;

