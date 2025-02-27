WITH RankedMovies AS (
    SELECT
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
        AND a.name <> ''
        AND t.production_year IS NOT NULL
        AND t.production_year > 2000
),
TopMovies AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieCompanies AS (
    SELECT 
        tm.actor_name,
        tm.movie_title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_title = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.actor_name, tm.movie_title
),
NullLogicExample AS (
    SELECT
        actor_name,
        movie_title,
        companies,
        COALESCE(companies, 'No companies') AS company_list
    FROM 
        MovieCompanies
)
SELECT 
    nle.actor_name,
    nle.movie_title,
    nle.company_list,
    CASE 
        WHEN nle.companies IS NULL THEN 'No company linkage found'
        ELSE 'Linked to companies found'
    END AS linkage_status,
    EXISTS (
        SELECT 1
        FROM title tit
        WHERE tit.title = nle.movie_title
          AND tit.kind_id IS NULL
    ) AS bizarre_case_check
FROM 
    NullLogicExample nle
WHERE
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id IN (
            SELECT t.id
            FROM aka_title t
            WHERE t.title = nle.movie_title
              AND (t.note IS NULL OR t.note NOT LIKE '%banned%')
        )
    )
ORDER BY 
    nle.actor_name ASC,
    nle.movie_title DESC;
