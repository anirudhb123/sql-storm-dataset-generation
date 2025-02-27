WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        cp.kind AS company_type
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON ci.movie_id = t.id AND ci.id = cc.subject_id
    JOIN
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN
        company_type cp ON cp.id = mc.company_type_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.title, t.production_year, ak.name, ak.id, cp.kind
),
ActorCounts AS (
    SELECT
        actor_id,
        COUNT(movie_title) AS movie_count
    FROM
        MovieDetails
    GROUP BY
        actor_id
)
SELECT
    md.movie_title,
    md.production_year,
    md.actor_name,
    ac.movie_count,
    md.keywords,
    md.company_type
FROM
    MovieDetails md
JOIN
    ActorCounts ac ON md.actor_id = ac.actor_id
ORDER BY
    ac.movie_count DESC, md.production_year DESC;
