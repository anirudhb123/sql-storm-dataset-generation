WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS keyword,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
top_movies AS (
    SELECT 
        movie_id, 
        movie_title,
        production_year,
        keyword,
        total_cast_members
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    string_agg(DISTINCT tm.keyword, ', ') AS keywords,
    string_agg(DISTINCT p.info, '; ') AS person_infos,
    string_agg(DISTINCT p.name, ', ') AS cast_names
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name p ON cc.subject_id = p.person_id
LEFT JOIN 
    person_info pi ON p.id = pi.person_id
WHERE 
    pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Birthdate')
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC;
