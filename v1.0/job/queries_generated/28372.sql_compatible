
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CAST(pi.info AS numeric)) AS avg_rating
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id AND it.info = 'rating'
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        avg_rating,
        ROW_NUMBER() OVER (ORDER BY avg_rating DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year, 
    tm.cast_count,
    akn.name AS actor_name,
    kt.kind AS kind_of_movie
FROM 
    top_movies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    aka_name akn ON akn.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = tm.movie_id)
JOIN 
    kind_type kt ON tm.movie_id = kt.id
WHERE 
    tm.rank <= 10 AND
    cn.country_code = 'USA'
ORDER BY 
    tm.avg_rating DESC, tm.title;
