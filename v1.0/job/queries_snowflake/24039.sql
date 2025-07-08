
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'film%')
),
ActorRoleCounts AS (
    SELECT
        c.movie_id,
        c.role_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    INNER JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, c.role_id
),
DistinctKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MoviesWithCount AS (
    SELECT
        rm.movie_id,
        COUNT(ac.actor_count) AS total_roles,
        COALESCE(dk.keywords, 'No Keywords') AS keywords_summary,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorRoleCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN
        DistinctKeywords dk ON rm.movie_id = dk.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, dk.keywords
    HAVING
        COUNT(ac.actor_count) > 1
)
SELECT
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.total_roles,
    mwc.keywords_summary,
    
    CASE
        WHEN mwc.total_roles < 5 THEN 'Few Roles'
        WHEN mwc.total_roles BETWEEN 5 AND 10 THEN 'Moderate Roles'
        ELSE 'Many Roles'
    END AS role_description,

    CASE
        WHEN mwc.keywords_summary IS NULL THEN 'No keywords found'
        ELSE 'Keywords are present'
    END AS keyword_description,

    (SELECT LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name)
     FROM name n
     WHERE EXISTS (
         SELECT 1 FROM cast_info ci
         WHERE ci.movie_id = mwc.movie_id AND ci.person_id = n.imdb_id
     )
    ) AS actor_names

FROM
    MoviesWithCount mwc
WHERE
    mwc.total_roles IS NOT NULL
ORDER BY
    mwc.production_year DESC, 
    mwc.total_roles DESC
LIMIT 50;
