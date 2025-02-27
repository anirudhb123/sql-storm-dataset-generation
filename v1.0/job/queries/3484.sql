WITH RankedTitles AS (
    SELECT
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.movie_id) AS num_movies
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title m ON c.movie_id = m.id
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY
        a.id, a.name, m.title, m.production_year
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    a.actor_name,
    a.num_movies,
    ARRAY_AGG(DISTINCT t.title) AS titles,
    c.company_count,
    CASE 
        WHEN a.num_movies > 5 THEN 'High'
        WHEN a.num_movies BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS activity_level
FROM
    ActorMovies a
LEFT JOIN
    CompanyMovies c ON a.production_year = c.movie_id
LEFT JOIN
    RankedTitles t ON a.production_year = t.production_year AND t.rank_year <= 5
WHERE
    a.num_movies > 2
GROUP BY
    a.actor_name, a.num_movies, c.company_count
ORDER BY
    a.num_movies DESC
LIMIT 100;
