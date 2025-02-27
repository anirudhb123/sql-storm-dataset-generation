WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC, a.title) AS rank
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.keywords
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
)
SELECT
    t.title AS Top_Movie_Title,
    t.production_year AS Production_Year,
    t.actor_count AS Number_of_Actors,
    t.keywords AS Associated_Keywords
FROM
    TopMovies t
JOIN
    company_name co ON EXISTS (
        SELECT 1
        FROM movie_companies mc
        WHERE mc.movie_id = t.movie_id AND mc.company_id = co.id
    )
ORDER BY
    t.production_year DESC, t.actor_count DESC;
