WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        movie_id,
        title,
        year_rank,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CompanyMovieInfo AS (
    SELECT 
        tc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        title tc ON mc.movie_id = tc.id
    GROUP BY 
        tc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    cm.company_names,
    cm.company_count,
    CASE 
        WHEN cm.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present' 
    END AS company_status,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    TopRatedMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovieInfo cm ON tm.movie_id = cm.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, cm.company_names, cm.company_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
