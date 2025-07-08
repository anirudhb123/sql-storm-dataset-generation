
WITH RecursiveMovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CompaniesRanked AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS full_cast,
        COUNT(DISTINCT a.id) AS cast_count
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cc.movie_id
),
TopMovies AS (
    SELECT
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.full_cast, 'No Cast Available') AS full_cast,
        cc.cast_count
    FROM 
        RecursiveMovieInfo rm
    LEFT JOIN 
        CompleteCast cc ON rm.title_id = cc.movie_id
    WHERE 
        rm.title_rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.full_cast,
    CASE 
        WHEN tm.cast_count > 0 THEN 'Has Cast'
        ELSE 'Cast Not Available'
    END AS cast_status,
    COALESCE(cr.movie_id, -1) AS movie_id,
    cr.company_name,
    cr.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    CompaniesRanked cr ON tm.title_id = cr.movie_id AND cr.company_rank = 1
ORDER BY 
    tm.production_year DESC, 
    tm.title;
