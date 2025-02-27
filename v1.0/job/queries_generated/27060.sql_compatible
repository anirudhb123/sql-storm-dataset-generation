
WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE(AVG(mi.info_type_id), 0) AS avg_info_type,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT kc.keyword) DESC, COUNT(DISTINCT ci.person_id) DESC) AS rnk
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.title, m.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        keyword_count,
        cast_count,
        avg_info_type,
        rnk
    FROM 
        RankedMovies
    WHERE 
        rnk <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    tm.avg_info_type,
    (SELECT STRING_AGG(DISTINCT c.name || ' (' || rt.role || ')', ', ') 
     FROM cast_info ci 
     JOIN aka_name c ON ci.person_id = c.person_id 
     JOIN role_type rt ON ci.role_id = rt.id 
     WHERE ci.movie_id IN (SELECT m.id FROM aka_title m WHERE m.title = tm.title)) AS cast_details
FROM 
    TopMovies tm
ORDER BY 
    tm.keyword_count DESC, tm.cast_count DESC;
