WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(mr.rating) AS average_rating
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id
    LEFT JOIN 
        (SELECT movie_id, 
                AVG(rating) AS rating 
         FROM movie_info 
         WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
         GROUP BY movie_id) mr ON a.id = mr.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        average_rating,
        ROW_NUMBER() OVER (ORDER BY average_rating DESC, cast_count DESC) AS ranking
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.average_rating,
    p.name AS director_name,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    role_type r ON mc.company_type_id = r.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
         ci.movie_id, 
         a.name
     FROM 
         cast_info ci
     JOIN 
         aka_name a ON ci.person_id = a.person_id 
     WHERE 
         ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')) p ON tm.movie_id = p.movie_id
WHERE 
    tm.ranking <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.average_rating, p.name
ORDER BY 
    tm.average_rating DESC, tm.cast_count DESC;
