WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.title, a.production_year
),
HighCastMovies AS (
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
        cp.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY cp.name) AS company_rank
    FROM
        movie_companies m
    JOIN
        company_name cp ON m.company_id = cp.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
)
SELECT
    h.title,
    h.production_year,
    COALESCE(STRING_AGG(DISTINCT c.company_name, ', '), 'No Companies') AS companies,
    COALESCE(STRING_AGG(DISTINCT ct.company_type, ', '), 'No Types') AS company_types,
    h.num_cast
FROM
    HighCastMovies h
LEFT JOIN
    CompanyDetails c ON h.title = (SELECT title FROM aka_title WHERE id = (SELECT movie_id FROM movie_companies WHERE movie_id IN (SELECT movie_id FROM aka_title WHERE title = h.title) LIMIT 1))
LEFT JOIN
    (SELECT movie_id, STRING_AGG(DISTINCT kind, ', ') AS company_type FROM movie_companies mc 
     JOIN company_type ct ON mc.company_type_id = ct.id GROUP BY mc.movie_id) ct ON h.production_year = (SELECT production_year FROM aka_title WHERE id = (SELECT movie_id FROM movie_companies WHERE movie_id IN (SELECT movie_id FROM aka_title WHERE title = h.title) LIMIT 1))
GROUP BY
    h.title, h.production_year
ORDER BY
    h.production_year DESC, h.num_cast DESC;
