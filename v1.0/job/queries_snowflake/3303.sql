
WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rnk
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count
    FROM
        RankedMovies
    WHERE
        rnk <= 5
),
MoviesWithKeywords AS (
    SELECT
        t.title,
        t.production_year,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        TopMovies t
    LEFT JOIN
        movie_keyword mk ON t.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.title, t.production_year
),
CompanyMovies AS (
    SELECT
        a.title,
        a.production_year,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        a.title, a.production_year, c.name, ct.kind
)
SELECT
    mw.title,
    mw.production_year,
    mw.keywords,
    cm.company_name,
    cm.company_type
FROM
    MoviesWithKeywords mw
LEFT JOIN
    CompanyMovies cm ON mw.title = cm.title AND mw.production_year = cm.production_year
WHERE
    mw.production_year BETWEEN 2000 AND 2020
    AND (cm.company_name IS NOT NULL OR mw.keywords IS NOT NULL)
ORDER BY
    mw.production_year DESC, mw.title;
