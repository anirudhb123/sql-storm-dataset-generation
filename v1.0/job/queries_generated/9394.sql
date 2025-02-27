WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_names,
        rm.keyword_count,
        rm.company_count,
        DENSE_RANK() OVER (ORDER BY rm.keyword_count DESC, rm.company_count DESC) AS rank
    FROM 
        ranked_movies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    tm.keyword_count,
    tm.company_count
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
