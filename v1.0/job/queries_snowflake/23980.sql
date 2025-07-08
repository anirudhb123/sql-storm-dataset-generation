
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
DetailedInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_details,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS company_info_ratio
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    di.movie_id,
    di.title,
    di.production_year,
    di.cast_details,
    CASE 
        WHEN di.company_count IS NULL THEN 'No Companies'
        ELSE CAST(di.company_count AS STRING) || ' Companies'
    END AS company_info,
    ROUND(di.company_info_ratio * 100, 2) AS info_presence_percentage
FROM 
    DetailedInfo di
WHERE 
    di.production_year IS NOT NULL
ORDER BY 
    di.production_year DESC, di.cast_details;
