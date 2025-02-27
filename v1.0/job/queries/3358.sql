WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCount AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
)
SELECT 
    R.title,
    R.production_year,
    COALESCE(KC.keyword_count, 0) AS total_keywords,
    COALESCE(CR.role_count, 0) AS total_roles,
    COUNT(DISTINCT C.id) AS total_cast
FROM 
    RankedMovies R
LEFT JOIN 
    KeywordCount KC ON R.title_id = KC.movie_id
LEFT JOIN 
    CastRoles CR ON R.title_id = CR.movie_id
LEFT JOIN 
    complete_cast C ON R.title_id = C.movie_id
WHERE 
    R.rank = 1
GROUP BY 
    R.title_id, R.title, R.production_year, KC.keyword_count, CR.role_count
HAVING 
    COUNT(DISTINCT C.id) > 5
ORDER BY 
    R.production_year DESC;
