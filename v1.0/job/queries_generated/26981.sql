WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        co.kind AS company_type,
        a.name AS actor_name,
        p.gender AS actor_gender,
        ct.kind AS cast_type
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type co ON mc.company_type_id = co.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type ct ON ci.role_id = ct.id
    JOIN
        name p ON a.person_id = p.imdb_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
        AND ct.kind = 'Actor'
),
AggregatedData AS (
    SELECT
        md.production_year,
        COUNT(DISTINCT md.title_id) AS total_movies,
        COUNT(DISTINCT md.actor_name) AS total_actors,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies,
        STRING_AGG(DISTINCT md.company_type, ', ') AS company_types
    FROM
        MovieDetails md
    GROUP BY
        md.production_year
)
SELECT
    ad.production_year,
    ad.total_movies,
    ad.total_actors,
    ad.keywords,
    ad.companies,
    ad.company_types
FROM
    AggregatedData ad
ORDER BY
    ad.production_year DESC;
