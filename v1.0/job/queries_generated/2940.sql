WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mk.keyword) DESC) as rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.note,
        rt.role,
        COALESCE((SELECT COUNT(*) FROM complete_cast cc WHERE cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id), 0) AS complete_cast_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    DISTINCT tm.title,
    tm.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(ci.complete_cast_count) AS avg_complete_casts
FROM 
    TopMovies tm
LEFT JOIN 
    CastInfoWithRoles ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
GROUP BY 
    tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    tm.production_year DESC, total_cast DESC;
