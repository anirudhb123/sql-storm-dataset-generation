WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        movie_rank <= 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    COALESCE(COUNT(DISTINCT ci.person_id), 0) AS actor_count,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = tm.movie_id
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, actor_count DESC;
