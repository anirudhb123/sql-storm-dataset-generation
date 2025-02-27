WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS actor_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
ComplicatedData AS (
    SELECT
        rn.movie_id,
        rn.title,
        rn.production_year,
        rn.actor_count,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rn.movie_id) AS company_count,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rn.movie_id AND mi.info_type_id = 1) AS info_count,
        COALESCE(MAX(k.id), -1) AS keyword_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        RankedMovies rn
    LEFT JOIN
        movie_keyword mk ON rn.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        rn.rank <= 3 AND rn.actor_count > 0
    GROUP BY
        rn.movie_id, rn.title, rn.production_year, rn.actor_count
),
FinalOutput AS (
    SELECT
        cd.movie_id,
        cd.title,
        cd.production_year,
        cd.actor_count,
        cd.company_count,
        cd.info_count,
        CD.keywords,
        CASE
            WHEN cd.info_count > 0 THEN 'Has Info'
            ELSE 'No Info'
        END AS info_status
    FROM
        ComplicatedData cd
    WHERE
        cd.actor_count IS NOT NULL AND cd.company_count IS NOT NULL
)
SELECT
    fo.*,
    CASE WHEN EXISTS (
        SELECT 1
        FROM movie_link ml
        WHERE ml.movie_id = fo.movie_id
    ) THEN 'Linked Movie Exists'
    ELSE 'No Linked Movie'
    END AS link_status,
    COUNT(ci.id) FILTER (WHERE ci.person_role_id IS NOT NULL AND ci.note IS NOT NULL) AS validated_cast_count
FROM
    FinalOutput fo
LEFT JOIN
    cast_info ci ON fo.movie_id = ci.movie_id
GROUP BY
    fo.movie_id, fo.title, fo.production_year, fo.actor_count, fo.company_count, fo.info_count, fo.keywords, fo.info_status
ORDER BY
    fo.actor_count DESC, fo.production_year DESC
LIMIT 10;

