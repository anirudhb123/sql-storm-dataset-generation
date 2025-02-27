WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title m
    JOIN complete_cast cc ON m.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        aka_names, 
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM ranked_movies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    tm.keywords
FROM top_movies tm
WHERE tm.movie_rank <= 10
ORDER BY tm.cast_count DESC;
