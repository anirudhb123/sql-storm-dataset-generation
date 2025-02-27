WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank_per_year <= 5
),
company_details AS (
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
    STRING_AGG(DISTINCT cd.company_name, ', ') AS companies_involved,
    (SELECT 
        COUNT(DISTINCT ci.person_id) 
     FROM 
        complete_cast cc 
     JOIN 
        cast_info ci ON cc.subject_id = ci.person_id 
     WHERE 
        cc.movie_id = tm.movie_id) AS distinct_cast_count
FROM 
    top_movies tm
LEFT JOIN 
    company_details cd ON tm.movie_id = cd.movie_id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, 
    COUNT(cd.company_name) DESC;
