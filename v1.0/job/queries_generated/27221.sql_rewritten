WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(cm.id) AS company_count,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cm.id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        movie_companies cm ON t.id = cm.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
SelectedMovies AS (
    SELECT
        RM.movie_id,
        RM.title,
        RM.production_year,
        RM.company_count,
        RM.keyword_count
    FROM
        RankedMovies RM
    WHERE
        RM.rank <= 10  
),
ActorDetails AS (
    SELECT
        a.name AS actor_name,
        ci.movie_id,
        t.title,
        ci.nr_order
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        SelectedMovies t ON ci.movie_id = t.movie_id
)
SELECT
    SM.title,
    SM.production_year,
    SM.company_count,
    SM.keyword_count,
    AD.actor_name,
    AD.nr_order
FROM
    SelectedMovies SM
LEFT JOIN
    ActorDetails AD ON SM.movie_id = AD.movie_id
ORDER BY
    SM.production_year DESC,
    SM.company_count DESC,
    AD.nr_order;