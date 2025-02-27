WITH RankedMovies AS (
    SELECT
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title mt
    JOIN
        complete_cast cc ON mt.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.title, mt.production_year
),
TopActors AS (
    SELECT
        ak.name,
        COUNT(DISTINCT cc.movie_id) AS movies_played
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        complete_cast cc ON ci.movie_id = cc.movie_id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        ak.name
    HAVING
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.name IS NOT NULL
),
GenreTitles AS (
    SELECT
        mt.title,
        kt.keyword AS genre
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword kt ON mk.keyword_id = kt.id
)
SELECT
    rm.title,
    rm.production_year,
    rm.actor_count,
    ta.movies_played,
    cm.company_name,
    cm.company_type,
    gt.genre
FROM
    RankedMovies rm
LEFT JOIN
    TopActors ta ON rm.actor_count > 10  -- only include if more than 10 actors
LEFT JOIN
    CompanyMovies cm ON rm.title = cm.movie_id
LEFT JOIN
    GenreTitles gt ON rm.title = gt.title
WHERE
    (rm.rank <= 3 OR gt.genre IS NOT NULL)
ORDER BY
    rm.production_year DESC, rm.actor_count DESC;
