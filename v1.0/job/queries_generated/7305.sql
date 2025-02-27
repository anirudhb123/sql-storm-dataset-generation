WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ck.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ki.info_type_id DESC) AS rank
    FROM
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword ck ON mk.keyword_id = ck.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type ki ON mi.info_type_id = ki.id
    WHERE 
        t.production_year > 2000
        AND ci.nr_order < 5
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    ranked_movies
WHERE 
    rank = 1
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
