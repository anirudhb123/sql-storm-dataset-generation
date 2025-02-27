WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN i.info IS NOT NULL THEN LENGTH(i.info) ELSE 0 END) AS avg_info_length,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
        LEFT JOIN cast_info c ON t.movie_id = c.movie_id
        LEFT JOIN movie_info i ON t.movie_id = i.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.cast_count,
        m.avg_info_length
    FROM 
        RankedMovies m
    WHERE 
        m.rank <= 3
),

MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
        INNER JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title,
    tm.cast_count,
    tm.avg_info_length,
    COALESCE(mc.company_names, 'No Companies') AS companies,
    CASE 
        WHEN mc.total_companies IS NULL THEN 'N/A'
        WHEN mc.total_companies = 0 THEN 'No Companies'
        ELSE CONCAT(mc.total_companies, ' Companies')
    END AS company_info,
    (SELECT STRING_AGG(DISTINCT keyword.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword ON mk.keyword_id = keyword.id 
     WHERE mk.movie_id = tm.movie_id) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.avg_info_length > (SELECT AVG(avg_info_length) FROM TopMovies) OR mc.company_names IS NOT NULL
ORDER BY 
    tm.cast_count DESC, tm.title;
