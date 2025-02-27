WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        array_agg(DISTINCT c.name) AS companies
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name,
        a.gender,
        array_agg(DISTINCT t.title) AS movies,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ca ON a.person_id = ca.person_id
    JOIN
        title t ON ca.movie_id = t.id
    GROUP BY
        a.id, a.name, a.gender
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    ad.actor_id,
    ad.name AS actor_name,
    ad.gender,
    ad.movie_count
FROM
    MovieDetails md
JOIN
    cast_info ci ON ci.movie_id = md.movie_id
JOIN
    aka_name an ON an.person_id = ci.person_id
JOIN
    ActorDetails ad ON an.id = ad.actor_id
ORDER BY
    md.production_year DESC, ad.movie_count DESC;
