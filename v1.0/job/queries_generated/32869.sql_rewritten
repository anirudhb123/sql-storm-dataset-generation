WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        id,
        title,
        production_year,
        episode_of_id,
        1 AS level
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL
    UNION ALL
    SELECT 
        a.id,
        a.title,
        a.production_year,
        a.episode_of_id,
        mh.level + 1
    FROM 
        aka_title a
    JOIN 
        movie_hierarchy mh ON a.episode_of_id = mh.id
),
movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.production_year,
        mc.cast_count,
        RANK() OVER (ORDER BY mc.cast_count DESC) AS rank
    FROM 
        movie_cast mc
    WHERE 
        mc.production_year >= 2000
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_selection AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        ks.unique_keywords
    FROM 
        top_movies tm
    JOIN 
        keyword_stats ks ON tm.movie_id = ks.movie_id
    WHERE 
        tm.rank <= 10
)

SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(f.unique_keywords, 0) AS keywords,
    CASE 
        WHEN f.cast_count IS NULL THEN 'No Cast Info'
        WHEN f.cast_count >= 10 THEN 'Well Cast'
        ELSE 'Under Cast'
    END AS cast_quality
FROM 
    final_selection f
LEFT JOIN 
    aka_title at ON f.title = at.title
WHERE 
    at.production_year IS NOT NULL
ORDER BY 
    f.production_year DESC,
    f.cast_count DESC;