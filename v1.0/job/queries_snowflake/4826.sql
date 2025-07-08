WITH MovieStats AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count, keyword_count
    FROM 
        MovieStats
    WHERE 
        rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keyword_count,
    COALESCE(p.name, 'Unknown') AS lead_actor_name,
    COALESCE(CAST(SUM(CASE WHEN mc.company_type_id IS NULL THEN 1 ELSE 0 END) AS integer), 0) AS uncredited_company_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name p ON cc.subject_id = p.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.keyword_count, p.name
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
