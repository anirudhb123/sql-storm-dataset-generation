WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count,
        RANK() OVER (PARTITION BY rm.keyword ORDER BY rm.cast_count DESC) AS rank
    FROM 
        ranked_movies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.cast_count
FROM 
    top_movies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.keyword, tm.cast_count DESC;

