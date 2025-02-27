WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM ranked_movies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    companies,
    keywords
FROM 
    top_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
