WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS top_cast,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        top_movies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = cc.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.top_cast,
    md.keyword_count,
    COALESCE(mo.info, 'No Info Available') AS additional_info
FROM 
    movie_details md
LEFT JOIN 
    movie_info mo ON md.production_year = mo.movie_id
WHERE 
    md.keyword_count > 2
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
