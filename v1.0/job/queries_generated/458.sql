WITH ranked_movies AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
top_actors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) as movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 3
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') as keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    ta.name AS Actor_Name,
    COALESCE(mk.keywords, 'No keywords') AS Movie_Keywords,
    RANK() OVER (PARTITION BY tm.production_year ORDER BY tm.production_year DESC) AS Year_Rank
FROM 
    ranked_movies tm
JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
JOIN 
    top_actors ta ON cc.subject_id = ta.person_id
LEFT JOIN 
    movie_keywords mk ON tm.title_id = mk.movie_id
WHERE 
    tm.rank <= 5 AND 
    ta.movie_count > 2
ORDER BY 
    tm.production_year DESC, 
    ta.name ASC;
