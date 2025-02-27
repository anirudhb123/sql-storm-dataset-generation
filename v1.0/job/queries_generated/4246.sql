WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
CompanyDetails AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        CASE WHEN m.note IS NULL THEN 'No Note' ELSE m.note END AS note
    FROM
        movie_companies m
    INNER JOIN
        company_name c ON m.company_id = c.id
    INNER JOIN
        company_type ct ON m.company_type_id = ct.id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    cd.company_type,
    cd.note
FROM
    TopMovies tm
LEFT JOIN
    CompanyDetails cd ON tm.title = cd.movie_id
WHERE
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = tm.id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Budget'
        )
    )
ORDER BY
    tm.production_year DESC, 
    tm.title;
