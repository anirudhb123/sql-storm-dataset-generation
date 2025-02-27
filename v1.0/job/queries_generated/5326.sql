WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    COALESCE(kw.keyword, 'No Keywords') AS keywords, 
    COALESCE(comp.name, 'Unknown Company') AS production_company
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year)
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year)
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
