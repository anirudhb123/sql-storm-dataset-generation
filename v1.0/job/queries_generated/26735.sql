WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC, mt.title) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.company_count, 
        rm.keyword_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.company_count,
    string_agg(DISTINCT ak.name, ', ') AS aka_names,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    string_agg(DISTINCT cn.name, ', ') AS company_names
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title ak ON tm.movie_id = ak.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.company_count, tm.keyword_count
ORDER BY 
    tm.production_year DESC;
