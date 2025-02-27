WITH movie_details AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        group_concat(DISTINCT c.name) AS cast_names,
        group_concat(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
), 
top_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_names,
        md.keywords,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY COUNT(md.cast_names) DESC) AS movie_rank
    FROM 
        movie_details md
    GROUP BY 
        md.movie_title, md.production_year, md.cast_names, md.keywords
    HAVING 
        COUNT(md.cast_names) > 2
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_names,
    tm.keywords
FROM 
    top_movies tm
WHERE 
    tm.movie_rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.movie_rank;
