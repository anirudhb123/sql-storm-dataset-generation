
WITH TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
        AND ak.md5sum IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.all_aka_names,
    tm.all_keywords
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    cn.country_code IN ('USA', 'UK')
ORDER BY 
    tm.production_year DESC;
