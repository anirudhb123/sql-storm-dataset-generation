WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        AVG(COALESCE(mr.rating, 0)) OVER (PARTITION BY t.id) AS avg_rating
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = t.id
    LEFT JOIN
        movie_info mi ON mi.movie_id = t.id
    LEFT JOIN
        (SELECT movie_id, AVG(rating) AS rating FROM movie_ratings GROUP BY movie_id) mr ON mr.movie_id = t.id
    WHERE
        t.production_year >= 2000
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON cn.id = mc.company_id
    GROUP BY
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.avg_rating,
        cm.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON cm.movie_id = rm.movie_id
    WHERE
        rm.total_cast > 5 AND
        (rm.avg_rating IS NULL OR rm.avg_rating > 7.0)
)
SELECT 
    f.title,
    f.production_year,
    f.total_cast,
    COALESCE(f.companies, 'No Companies') AS companies_info
FROM 
    FilteredMovies f
ORDER BY 
    f.avg_rating DESC NULLS LAST,
    f.production_year DESC;
