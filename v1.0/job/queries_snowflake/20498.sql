
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ka.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 3
),
movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title t ON mk.movie_id = t.id
    GROUP BY 
        t.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mkw.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id AND ci.note IS NOT NULL) AS non_null_cast_count,
    (SELECT AVG(mo.rank) 
     FROM (SELECT 
               DISTINCT rc.rank 
           FROM 
               ranked_movies rc 
           WHERE 
               rc.production_year = tm.production_year) mo) AS avg_rank_of_year
FROM 
    top_movies tm
LEFT JOIN 
    movies_with_keywords mkw ON tm.movie_id = mkw.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
