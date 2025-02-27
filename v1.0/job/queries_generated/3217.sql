WITH ranked_movies AS (
    SELECT
        m.title,
        m.production_year,
        COUNT(c.person_id) AS actor_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        avg_order
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        top_movies m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.avg_order,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = m.id) as company_count
FROM 
    top_movies m
LEFT JOIN 
    movie_keywords mk ON m.title = mk.title
ORDER BY 
    m.production_year ASC, m.actor_count DESC;
