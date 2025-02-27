WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
keyword_movies AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COUNT(m.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id, k.keyword
),
most_frequent_keyword AS (
    SELECT 
        movie_id,
        keyword,
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY keyword_count DESC) AS keyword_rank
    FROM 
        keyword_movies
),
final_output AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.actor_name,
        mfk.keyword
    FROM 
        ranked_titles rt
    JOIN 
        most_frequent_keyword mfk ON rt.title = mfk.movie_id
    WHERE 
        mfk.keyword_rank = 1
)
SELECT 
    title,
    production_year,
    actor_name,
    keyword
FROM 
    final_output
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, title ASC;
