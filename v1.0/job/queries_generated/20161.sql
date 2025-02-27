WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
ActorStats AS (
    SELECT
        a.person_id,
        COUNT(c.movie_id) AS total_movies,
        AVG(CASE WHEN c.note IS NULL THEN 0 ELSE 1 END) AS has_note_avg
    FROM
        cast_info c
    JOIN
        aka_name a ON a.person_id = c.person_id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        a.person_id
),
TopActors AS (
    SELECT
        a.person_id,
        a.name,
        s.total_movies,
        s.has_note_avg
    FROM
        aka_name a
    JOIN
        ActorStats s ON a.person_id = s.person_id
    WHERE
        s.total_movies > 3
    ORDER BY
        s.total_movies DESC
    LIMIT 10
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    a.name AS actor_name,
    COALESCE(mcc.company_count, 0) AS company_count,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(cast_scores.avg_role_id, 0) AS avg_role_id
FROM
    RankedMovies m
LEFT JOIN (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
) mcc ON m.movie_id = mcc.movie_id
LEFT JOIN (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
) k ON m.movie_id = k.movie_id
LEFT JOIN (
    SELECT
        c.movie_id,
        AVG(role_id) AS avg_role_id
    FROM
        cast_info c
    GROUP BY
        c.movie_id
) cast_scores ON m.movie_id = cast_scores.movie_id
JOIN
    TopActors a ON a.person_id IN (
        SELECT DISTINCT person_id 
        FROM cast_info 
        WHERE movie_id = m.movie_id
    )
WHERE
    m.rank <= 5
ORDER BY
    m.production_year DESC, 
    a.total_movies DESC,
    m.title;
