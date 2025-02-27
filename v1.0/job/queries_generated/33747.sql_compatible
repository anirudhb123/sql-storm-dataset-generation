
WITH RECURSIVE RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        rm.movie_id,
        COUNT(c.id) AS cast_count,
        AVG(COALESCE(CAST(pi.info AS FLOAT), 0)) AS avg_salary,
        STRING_AGG(DISTINCT g.keyword, ', ') AS genres
    FROM 
        RankedMovies rm
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword g ON mk.keyword_id = g.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'salary')
    GROUP BY 
        rm.movie_id
),
MoviesWithCompany AS (
    SELECT 
        t.title, 
        t.production_year, 
        mcc.company_id, 
        c.name AS company_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mcc ON t.id = mcc.movie_id
    JOIN 
        company_name c ON mcc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
),
FilteredMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(s.cast_count, 0) AS cast_count,
        COALESCE(s.avg_salary, 0) AS avg_salary,
        (SELECT COUNT(*) FROM MoviesWithCompany mwc WHERE mwc.title = m.title) AS company_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieStats s ON m.movie_id = s.movie_id
)
SELECT 
    *,
    CASE 
        WHEN avg_salary > 100000 THEN 'High Budget'
        WHEN avg_salary >= 50000 THEN 'Medium Budget'
        ELSE 'Low Budget'
    END AS budget_category
FROM 
    FilteredMovies
WHERE 
    cast_count > 0
ORDER BY 
    production_year DESC, cast_count DESC;
