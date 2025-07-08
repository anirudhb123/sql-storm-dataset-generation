
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)

SELECT 
    fm.title AS "Movie Title",
    fm.production_year AS "Year",
    fm.keywords AS "Associated Keywords",
    fm.cast_count AS "Number of Cast Members"
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
