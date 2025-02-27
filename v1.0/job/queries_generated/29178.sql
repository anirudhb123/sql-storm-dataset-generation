WITH movie_counts AS (
    SELECT 
        a.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = a.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.movie_id
    GROUP BY 
        a.title
),
top_movies AS (
    SELECT 
        title,
        cast_count,
        company_count,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC, company_count DESC, keyword_count DESC) AS ranking
    FROM 
        movie_counts
)
SELECT 
    tm.title,
    tm.cast_count,
    tm.company_count,
    tm.keyword_count,
    GROUP_CONCAT(DISTINCT ak.name) AS actors,
    GROUP_CONCAT(DISTINCT cn.name) AS companies,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT a.movie_id FROM aka_title a WHERE a.title = tm.title LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT a.movie_id FROM aka_title a WHERE a.title = tm.title LIMIT 1)
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT a.movie_id FROM aka_title a WHERE a.title = tm.title LIMIT 1)
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE 
    tm.ranking <= 10
GROUP BY 
    tm.title, tm.cast_count, tm.company_count, tm.keyword_count
ORDER BY 
    tm.ranking;
