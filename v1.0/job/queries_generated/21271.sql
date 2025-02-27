WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.imdb_index,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        th.depth + 1
    FROM 
        aka_title t
    INNER JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id 
    WHERE 
        th.depth < 5
),
person_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
filtered_movies AS (
    SELECT 
        th.title_id,
        th.title,
        th.production_year,
        pk.keywords,
        COALESCE(pc.cast_count, 0) AS cast_count
    FROM 
        title_hierarchy th
    LEFT JOIN 
        movie_keywords pk ON th.title_id = pk.movie_id
    LEFT JOIN 
        person_cast pc ON th.title_id = pc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.cast_count,
    COALESCE(fm.production_year, 'Unknown Year') AS year_or_unknown,
    CASE 
        WHEN fm.cast_count > 10 THEN 'Large Cast'
        WHEN fm.cast_count BETWEEN 1 AND 10 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_size,
    ROW_NUMBER() OVER (PARTITION BY fm.production_year ORDER BY RANDOM()) AS random_rank
FROM 
    filtered_movies fm
WHERE 
    fm.cast_count IS NOT NULL 
    AND fm.keywords LIKE '%action%'
ORDER BY 
    fm.production_year DESC,
    fm.cast_count DESC,
    random_rank
LIMIT 100;
