WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.cast_count,
        mc.actor_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_cast mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.year_rank <= 5 AND 
        (mc.cast_count IS NULL OR mc.cast_count > 5)
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS total_cast,
    COALESCE(fk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN fm.production_year >= 2000 THEN 'Modern'
        WHEN fm.production_year < 2000 AND fm.production_year >= 1980 THEN 'Classic'
        ELSE 'Vintage'
    END AS era
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_keywords fk ON fm.movie_id = fk.movie_id
ORDER BY 
    fm.production_year, fm.title;
