WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        SUM(CASE WHEN rk.kind LIKE '%Drama%' THEN 1 ELSE 0 END) AS drama_company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_type rk ON m.company_type_id = rk.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        company_count,
        drama_company_count,
        RANK() OVER (ORDER BY company_count DESC, drama_company_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.drama_company_count,
    ak.name AS actor_name,
    rk.role AS role_name
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    role_type rk ON cc.role_id = rk.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank, ak.name;
