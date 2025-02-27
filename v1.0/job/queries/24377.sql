WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        aka_title AS t
    JOIN
        cast_info AS ci ON t.id = ci.movie_id
    WHERE
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year
),
KeyedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
    FROM
        RankedMovies AS rm
    LEFT JOIN
        movie_keyword AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
MovieCompanyDetails AS (
    SELECT
        cm.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        m.note AS movie_note
    FROM
        movie_companies AS cm
    JOIN
        company_name AS c ON cm.company_id = c.id
    JOIN
        company_type AS ct ON cm.company_type_id = ct.id
    LEFT JOIN
        movie_info AS m ON cm.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
),
FinalOutput AS (
    SELECT
        km.movie_id,
        km.title,
        km.production_year,
        km.keywords,
        COALESCE(mc.company_name, 'Unknown') AS company_name,
        COALESCE(mc.company_type, 'N/A') AS company_type,
        COALESCE(mc.movie_note, 'No Note Available') AS movie_note
    FROM
        KeyedMovies AS km
    LEFT JOIN
        MovieCompanyDetails AS mc ON km.movie_id = mc.movie_id
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords,
    f.company_name,
    f.company_type,
    f.movie_note
FROM
    FinalOutput AS f
WHERE
    f.production_year BETWEEN 2015 AND 2023
    AND f.keywords NOT LIKE '%documentary%' 
ORDER BY
    f.production_year DESC, f.title
LIMIT 100;