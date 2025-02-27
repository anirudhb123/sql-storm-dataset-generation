WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') FILTER (WHERE an.name IS NOT NULL) AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year >= 2000
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    mk.keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank <= 10 AND 
    (tm.cast_count > 5 OR tm.actor_names IS NOT NULL)
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC
LIMIT 20;
