WITH movie_details AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.kind AS cast_type,
        p.name AS person_name,
        a.imdb_index AS movie_imdb_index
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        a.production_year > 2000
        AND k.keyword LIKE '%action%'
), ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        person_name,
        movie_imdb_index,
        ROW_NUMBER() OVER (PARTITION BY movie_title ORDER BY production_year DESC) AS movie_rank
    FROM 
        movie_details
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.person_name,
    rm.movie_imdb_index
FROM 
    ranked_movies rm
WHERE 
    rm.movie_rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
