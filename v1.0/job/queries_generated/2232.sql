WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info cc ON cc.movie_id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_title,
    COALESCE(AC.name, 'Unknown') AS actor_name,
    tm.production_year,
    CASE 
        WHEN pp.info IS NOT NULL THEN pp.info 
        ELSE 'No Info Available' 
    END AS person_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
LEFT JOIN 
    aka_name AN ON AN.person_id = ci.person_id
LEFT JOIN 
    person_info pp ON pp.person_id = AN.person_id AND pp.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    (SELECT person_id, name FROM char_name) AC ON AC.name = AN.name
WHERE 
    tm.production_year >= 2000
GROUP BY 
    tm.movie_title, actor_name, tm.production_year, pp.info
ORDER BY 
    tm.production_year DESC, tm.movie_title;
