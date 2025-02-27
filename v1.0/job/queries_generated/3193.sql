WITH MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
    GROUP BY
        t.id
),
RankedMovies AS (
    SELECT
        md.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM
        MovieDetails md
)

SELECT
    rm.title,
    rm.production_year,
    rm.actor_names,
    rm.company_count,
    COALESCE(NULLIF(rm.keyword_count, 0), 'No Keywords') AS keywords_info
FROM
    RankedMovies rm
WHERE
    rm.rank <= 5
ORDER BY
    rm.production_year DESC, rm.keyword_count DESC;

