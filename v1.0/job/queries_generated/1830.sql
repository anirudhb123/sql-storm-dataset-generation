WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.name
),
CompanyMovieCounts AS (
    SELECT
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM
        company_name cn
    JOIN
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY
        cn.name
    HAVING
        COUNT(DISTINCT mc.movie_id) > 5
)
SELECT
    rt.title,
    rt.production_year,
    ac.name AS actor_name,
    ac.movie_count AS actor_movies,
    cc.company_name,
    cc.movie_count AS company_movies
FROM
    RankedTitles rt
LEFT JOIN
    ActorMovieCounts ac ON ac.movie_count > 3
LEFT JOIN
    CompanyMovieCounts cc ON cc.movie_count > 5
WHERE
    rt.rn <= 3
ORDER BY
    rt.production_year DESC, ac.movie_count DESC, cc.movie_count DESC;
