WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS director_name,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank_by_keywords
    FROM 
        aka_title a
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        char_name cn ON an.name = cn.name
    JOIN 
        (SELECT person_id, MAX(role_id) AS max_role_id 
         FROM cast_info 
         WHERE person_role_id IN 
            (SELECT id FROM role_type WHERE role = 'Director')
         GROUP BY person_id) AS directed ON ci.person_id = directed.person_id
    JOIN 
        aka_name c ON directed.person_id = c.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    GROUP BY 
        a.id, a.title, a.production_year, c.name
)

SELECT 
    movie_title,
    production_year,
    director_name,
    keyword_count
FROM 
    RankedMovies
WHERE 
    rank_by_keywords <= 5
ORDER BY 
    production_year, keyword_count DESC;