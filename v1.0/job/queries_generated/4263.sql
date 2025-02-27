WITH RecentMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.person_id, a.name
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
TopActors AS (
    SELECT 
        ai.name,
        ai.movie_count,
        ROW_NUMBER() OVER (ORDER BY ai.movie_count DESC) AS rank
    FROM
        ActorInfo ai
    WHERE
        ai.movie_count > 3
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS top_actor,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
FROM
    RecentMovies rm
LEFT JOIN
    TopActors ta ON ta.rank = 1 AND rm.movie_id IN (
        SELECT movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id
    )
LEFT JOIN
    MovieKeywords mk ON mk.movie_id = rm.movie_id
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC, rm.title;
