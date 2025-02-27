WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRated AS (
    SELECT
        mc.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM
        complete_cast mc
    INNER JOIN
        cast_info c ON mc.movie_id = c.movie_id
    GROUP BY
        mc.movie_id
    HAVING
        COUNT(c.person_id) > 3
),
Producers AS (
    SELECT
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM
        movie_companies m
    JOIN
        company_name cn ON m.company_id = cn.id
    WHERE
        m.company_type_id = (SELECT id FROM company_type WHERE kind = 'Producer')
    GROUP BY
        m.movie_id
),
TitleAndProducers AS (
    SELECT
        a.title,
        a.production_year,
        p.companies
    FROM 
        RankedMovies a
    LEFT JOIN 
        Producers p ON a.movie_id = p.movie_id
    WHERE
        a.rn <= 5
)
SELECT 
    t.title,
    t.production_year,
    p.companies,
    COALESCE(t.title, 'Unknown Title') AS display_title,
    CASE 
        WHEN t.production_year > 2000 THEN 'Modern Era'
        WHEN t.production_year BETWEEN 1980 AND 2000 THEN 'Late 20th Century'
        ELSE 'Classic'
    END AS era,
    NULLIF(p.companies, '') AS companies_list
FROM 
    TitleAndProducers t
LEFT JOIN 
    TopRated tr ON t.movie_id = tr.movie_id
WHERE 
    tr.cast_count IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    t.title ASC
LIMIT 10 OFFSET 5;
