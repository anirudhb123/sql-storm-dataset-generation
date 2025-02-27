WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ak.name AS actor_name,
        r.role AS actor_role
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
        AND k.keyword LIKE '%action%'
),
ActorStatistics AS (
    SELECT
        actor_name,
        COUNT(DISTINCT title_id) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        MIN(production_year) AS first_appearance
    FROM
        MovieDetails
    GROUP BY
        actor_name
)
SELECT
    actor_name,
    movie_count,
    movies,
    production_companies,
    first_appearance,
    CASE
        WHEN movie_count >= 10 THEN 'Prolific Actor'
        WHEN movie_count BETWEEN 5 AND 9 THEN 'Established Actor'
        ELSE 'Rising Star'
    END AS actor_status
FROM
    ActorStatistics
ORDER BY
    movie_count DESC;
