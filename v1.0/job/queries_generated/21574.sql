WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name || ' (' || r.role || ')', ', ') AS actors
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id
),
MovieKeywords AS (
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
TopMovies AS (
    SELECT
        rm.title_id,
        rm.title,
        rm.production_year,
        cd.actor_count,
        cd.actors,
        mk.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, cd.actor_count DESC) AS top_rank
    FROM
        RankedMovies rm
    LEFT JOIN
        CastDetails cd ON rm.title_id = cd.movie_id
    LEFT JOIN
        MovieKeywords mk ON rm.title_id = mk.movie_id
    WHERE
        rm.title IS NOT NULL AND
        (cd.actor_count > 0 OR mk.keywords IS NOT NULL)
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS num_actors,
    COALESCE(tm.keywords, 'No keywords available') AS keywords,
    CASE
        WHEN tm.top_rank <= 10 THEN 'Top 10 Movie'
        WHEN tm.top_rank <= 50 THEN 'Top 50 Movie'
        ELSE 'Other'
    END AS ranking_category
FROM
    TopMovies tm
WHERE
    (tm.production_year BETWEEN 2000 AND 2023)
    AND (tm.keywords IS NOT NULL OR tm.num_actors > 5)
ORDER BY
    tm.production_year DESC, tm.num_actors DESC;
