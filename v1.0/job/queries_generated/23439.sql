WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_cast <= 5
),
null_checked_titles AS (
    SELECT 
        COALESCE(kt.keyword, 'None') AS keyword,
        COALESCE(ct.kind, 'Unknown') AS company_type
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        movie_companies mc ON mk.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT n.name, ', ') AS actors,
    ARRAY_AGG(DISTINCT n.gender) FILTER (WHERE n.gender IS NOT NULL) AS actor_genders,
    CASE 
        WHEN COUNT(DISTINCT nc.kind) > 1 THEN 'Varied'
        ELSE MAX(nc.kind)
    END AS varied_company_type,
    CASE 
        WHEN COUNT(DISTINCT kw.keyword) > 0 THEN STRING_AGG(DISTINCT kw.keyword, ', ')
        ELSE 'No Keywords'
    END AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type nc ON mc.company_type_id = nc.id
LEFT JOIN 
    null_checked_titles kw ON tm.movie_id = kw.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT n.name) > 2
ORDER BY 
    tm.production_year DESC, COUNT(DISTINCT n.name) DESC;
