WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT
        a.name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM
        aka_name a
    INNER JOIN
        cast_info c ON a.person_id = c.person_id
    WHERE
        a.name IS NOT NULL AND
        a.name <> ''
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
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ad.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'N/A') AS movie_keywords,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 of Year'
        ELSE 'Others'
    END AS movie_rank_category
FROM
    RankedMovies rm
LEFT JOIN (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS actor_count
    FROM
        cast_info
    GROUP BY
        movie_id
) ad ON rm.movie_id = ad.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY
    rm.production_year DESC, 
    rm.total_cast DESC;
