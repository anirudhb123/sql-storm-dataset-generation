
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count IS NULL THEN 'Unknown'
            ELSE 'Popular'
        END AS movie_type
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    COALESCE(cn.name, 'Anonymous') AS company_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT pi.info, ', ') WITHIN GROUP (ORDER BY pi.info) AS person_info
FROM 
    PopularMovies pm
LEFT JOIN 
    movie_companies mc ON pm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON pm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON pm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
GROUP BY 
    pm.title, pm.production_year, pm.cast_count, cn.name
ORDER BY 
    pm.production_year DESC, pm.cast_count DESC;
