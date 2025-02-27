WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.cast_count > 10
), film_aggregates AS (
    SELECT 
        production_year,
        AVG(cast_count) AS avg_cast_count,
        COUNT(movie_id) AS total_movies
    FROM 
        top_movies
    GROUP BY 
        production_year
)
SELECT 
    t.production_year,
    t.avg_cast_count,
    t.total_movies,
    COALESCE(m.keywords, 'No keywords') AS movie_keywords
FROM 
    film_aggregates t
LEFT JOIN 
    top_movies m ON t.production_year = m.production_year
WHERE 
    t.avg_cast_count IS NOT NULL
ORDER BY 
    t.production_year DESC, t.avg_cast_count DESC;
