WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        ranked_movies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
    GROUP_CONCAT(DISTINCT kn.keyword) AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kn ON mk.keyword_id = kn.id
LEFT JOIN 
    aka_title at ON tm.movie_id = at.movie_id
LEFT JOIN 
    aka_name ak ON at.id = ak.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
