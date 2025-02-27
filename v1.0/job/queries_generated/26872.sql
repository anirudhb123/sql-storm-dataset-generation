WITH popular_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        kt.kind AS genre, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        kind_type kt ON a.kind_id = kt.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, kt.kind
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
actor_info AS (
    SELECT 
        ak.name AS actor_name, 
        ak.id AS actor_id, 
        COUNT(DISTINCT c.movie_id) AS movies_participated
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, ak.id
    HAVING 
        movies_participated > 5
),
movie_details AS (
    SELECT 
        m.title AS movie_title, 
        m.production_year, 
        COALESCE(mk.keyword, 'No keywords') AS keyword,
        CASE 
            WHEN mi.info IS NOT NULL THEN mi.info 
            ELSE 'No additional info' 
        END AS additional_info
    FROM 
        popular_movies m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    md.movie_title, 
    md.production_year, 
    md.keyword, 
    md.additional_info, 
    actor.actor_name, 
    actor.movies_participated
FROM 
    movie_details md
JOIN 
    actor_info actor ON actor.movies_participated > 5
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    actor.movies_participated DESC;

This SQL query benchmarks string processing across various dimensions within the provided schema, focusing on popular movies post-2000, actors with substantial participation in film projects, and detailed movie information that includes keywords and additional info.
