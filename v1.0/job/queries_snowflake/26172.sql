
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mci.company_id) AS production_company_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_members,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mci.company_id) DESC) AS rank
    FROM
        aka_title m
    JOIN
        movie_companies mci ON mci.movie_id = m.id
    JOIN
        cast_info ci ON ci.movie_id = m.id
    JOIN
        aka_name c ON ci.person_id = c.person_id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.production_company_count,
        rm.cast_members
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
)
SELECT
    tm.title,
    tm.production_year,
    tm.production_company_count,
    LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_list
FROM
    TopMovies tm
JOIN
    cast_info ci ON ci.movie_id = tm.movie_id
JOIN
    aka_name c ON ci.person_id = c.person_id
GROUP BY
    tm.movie_id, tm.title, tm.production_year, tm.production_company_count
ORDER BY
    tm.production_year DESC, tm.production_company_count DESC;
