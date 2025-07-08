
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS movie_keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),

top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast,
        cast_names,
        movie_keywords,
        ROW_NUMBER() OVER (ORDER BY num_cast DESC) AS rank
    FROM 
        ranked_movies
)

SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.num_cast,
    tm.cast_names,
    tm.movie_keywords,
    rt.role AS role_type
FROM 
    top_movies tm
JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type rt ON mc.company_type_id = rt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
