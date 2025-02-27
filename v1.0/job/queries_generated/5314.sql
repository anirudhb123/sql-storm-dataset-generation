WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    GROUP BY 
        t.id, t.title, t.production_year
),
highest_cast_movies AS (
    SELECT * 
    FROM ranked_movies 
    WHERE rank <= 5
)
SELECT 
    h.movie_id, 
    h.title, 
    h.production_year, 
    h.total_cast, 
    h.companies, 
    pi.info AS person_info
FROM 
    highest_cast_movies h
LEFT JOIN 
    complete_cast cc ON cc.movie_id = h.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id = cc.subject_id
ORDER BY 
    h.production_year DESC, 
    h.total_cast DESC;
