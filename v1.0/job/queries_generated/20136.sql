WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
deep_cast_info AS (
    SELECT 
        m.movie_id,
        string_agg(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT dd.id) AS distinct_role_types
    FROM 
        ranked_movies m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type dd ON ci.role_id = dd.id
    WHERE 
        m.rank <= 5  -- Top 5 movies per year by actor count
    GROUP BY 
        m.movie_id
), 
movie_keywords AS (
    SELECT 
        movie_id,
        string_agg(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    dm.movie_id,
    dm.title,
    dm.production_year,
    dm.actors,
    dm.distinct_role_types,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN dm.distinct_role_types > 5 THEN 'Diverse casting'
        WHEN dm.distinct_role_types IS NULL THEN 'Unknown casting'
        ELSE 'Standard casting' 
    END AS casting_type
FROM 
    deep_cast_info dm
LEFT JOIN 
    movie_keywords mk ON dm.movie_id = mk.movie_id
WHERE 
    dm.actors IS NOT NULL 
    AND (dm.distinct_role_types IS NOT NULL OR dm.distinct_role_types > 0)
ORDER BY 
    dm.production_year DESC, 
    dm.distinct_role_types DESC
LIMIT 50;
