WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MIN(t.production_year) AS first_release,
        MAX(t.production_year) AS last_release
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
top_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        first_release >= 2000
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.cast_names,
    tm.cast_count,
    tm.keywords,
    tm.first_release,
    tm.last_release
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
