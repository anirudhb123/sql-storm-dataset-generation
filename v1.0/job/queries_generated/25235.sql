WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank_keyword
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
ActorMovies AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.movie_id) AS total_movies
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    WHERE
        a.name ILIKE '%Smith%'
    GROUP BY
        a.name, t.title, t.production_year
),
CompanyMovies AS (
    SELECT
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS num_movies
    FROM
        company_name cn
    JOIN
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY
        cn.name
    HAVING
        COUNT(DISTINCT mc.movie_id) > 5
),
FinalReport AS (
    SELECT
        a.actor_name,
        a.movie_title,
        a.production_year,
        ct.kind AS company_type,
        cm.num_movies AS company_movie_count,
        rt.keyword
    FROM
        ActorMovies a
    JOIN
        company_movies cm ON a.movie_title = cm.company_name
    JOIN
        kind_type ct ON cm.company_name = ct.kind
    JOIN
        RankedTitles rt ON a.movie_title = rt.title
    WHERE
        rt.rank_keyword = 1
)
SELECT
    actor_name,
    movie_title,
    production_year,
    company_type,
    company_movie_count,
    keyword
FROM
    FinalReport
ORDER BY
    actor_name, production_year DESC;
