WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title at
    JOIN complete_cast cc ON at.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY at.id, at.title, at.production_year, at.kind_id
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id
    FROM ranked_movies rm
    WHERE rm.rank <= 5
),
keyword_movies AS (
    SELECT 
        at.id AS movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM aka_title at
    JOIN movie_keyword mk ON at.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY at.id
)
SELECT 
    tm.title,
    tm.production_year,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM complete_cast cc 
     JOIN cast_info ci ON cc.subject_id = ci.id 
     WHERE cc.movie_id = tm.movie_id) AS actor_count,
    COALESCE(kw.keywords, 'No Keywords') AS keywords
FROM top_movies tm
LEFT JOIN keyword_movies kw ON tm.movie_id = kw.movie_id
ORDER BY tm.production_year DESC, actor_count DESC;
