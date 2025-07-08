
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_member_count,
        LISTAGG(DISTINCT ak.name, ', ') AS aka_names,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_member_count,
        aka_names
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 10
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.cast_member_count,
    CONCAT('A.K.A: ', tm.aka_names) AS aka_information,
    ct.kind AS company_type
FROM 
    top_movies AS tm
JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_member_count DESC;
