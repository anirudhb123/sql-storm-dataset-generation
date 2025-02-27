WITH RecursiveActorMovies AS (
    SELECT
        ca.person_id,
        at.movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS rn
    FROM
        cast_info ca
    JOIN
        aka_title at ON ca.movie_id = at.id
    WHERE
        ca.nr_order = 1  -- Selecting only the first role of each actor
),
MovieProductionYears AS (
    SELECT
        title_id,
        MIN(production_year) AS earliest_year,
        MAX(production_year) AS latest_year
    FROM
        aka_title
    GROUP BY
        title_id
),
KeywordMovies AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
ActorInfo AS (
    SELECT
        a.id AS actor_id,
        a.name,
        pi.info AS biography,
        COALESCE(ai.name_pcode_nf, 'Unknown') AS name_pcode_nf
    FROM
        aka_name a
    LEFT JOIN
        person_info pi ON a.person_id = pi.person_id
    LEFT JOIN
        char_name ai ON a.name = ai.name
)
SELECT
    a.name AS actor_name,
    am.title,
    am.production_year,
    km.keywords,
    am.earliest_year,
    am.latest_year,
    CASE
        WHEN am.rn = 1 THEN 'Lead Actor'
        WHEN am.production_year = cor.max_year THEN 'Most Recent Production'
        ELSE 'Supporting Role'
    END AS role_type
FROM
    RecursiveActorMovies am
JOIN
    MovieProductionYears cor ON am.movie_id = cor.title_id
JOIN
    KeywordMovies km ON am.movie_id = km.movie_id
LEFT JOIN
    ActorInfo a ON am.person_id = a.actor_id
WHERE
    am.rn <= 5  -- Retrieve top 5 movies per actor
    AND (EXTRACT(YEAR FROM CURRENT_DATE) - am.production_year) < 10  -- Only recent films
ORDER BY
    am.production_year DESC,
    a.name,
    am.title;
