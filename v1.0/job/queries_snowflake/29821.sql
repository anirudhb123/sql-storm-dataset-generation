
WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rank_by_company_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank_by_keyword_count
    FROM
        aka_title a
    LEFT JOIN
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.id, a.title, a.production_year
),
TopRankedMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM
        RankedMovies rm
    WHERE
        rm.rank_by_company_count <= 5 OR rm.rank_by_keyword_count <= 5
),
NamesWithRoles AS (
    SELECT
        p.name AS actor_name,
        r.role AS role_name,
        a.title AS movie_title,
        a.production_year
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        aka_title a ON c.movie_id = a.id
)
SELECT
    twm.title,
    twm.production_year,
    twm.company_count,
    twm.keyword_count,
    LISTAGG(DISTINCT nwr.actor_name || ' (' || nwr.role_name || ')', ', ') WITHIN GROUP (ORDER BY nwr.actor_name) AS cast_details
FROM
    TopRankedMovies twm
LEFT JOIN
    NamesWithRoles nwr ON twm.title = nwr.movie_title AND twm.production_year = nwr.production_year
GROUP BY
    twm.title, twm.production_year, twm.company_count, twm.keyword_count
ORDER BY
    twm.production_year DESC, twm.company_count DESC;
