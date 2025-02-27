WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ki.keyword) AS keywords,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, mi.info
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    cmi.company_names, 
    cmi.keywords, 
    cmi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieInfo cmi ON rm.title = cmi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
