WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    COALESCE(ci.country_code, 'Unknown') AS country
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    (SELECT DISTINCT ci.movie_id, coalesce(cn.country_code, 'Unknown') AS country_code
     FROM movie_companies ci
     LEFT JOIN company_name cn ON ci.company_id = cn.id) AS ci 
ON 
    ci.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
