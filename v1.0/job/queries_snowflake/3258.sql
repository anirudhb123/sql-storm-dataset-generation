
WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actor_count
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.title, a.production_year
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
ComplexMovieInfo AS (
    SELECT
        t.title,
        t.production_year,
        COALESCE(ki.info, 'No Info Available') AS info,
        mk.keywords
    FROM
        title t
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN
        MovieKeywords mk ON t.id = mk.movie_id
    LEFT JOIN
        info_type ki ON mi.info_type_id = ki.id
)
SELECT
    cm.title,
    cm.production_year,
    cm.info,
    cm.keywords,
    rm.actor_count,
    rm.rank_by_actor_count
FROM
    ComplexMovieInfo cm
JOIN
    RankedMovies rm ON cm.title = rm.title AND cm.production_year = rm.production_year
WHERE
    (rm.actor_count IS NOT NULL AND rm.actor_count > 5)
    OR (cm.keywords LIKE '%action%' AND cm.production_year >= 2000)
ORDER BY
    rm.rank_by_actor_count, cm.production_year DESC;
