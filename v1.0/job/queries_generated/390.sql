WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cm.company_name, 'Independent') AS company_name,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    tm.cast_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.title, tm.production_year, cm.company_name, ct.kind, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.title;
