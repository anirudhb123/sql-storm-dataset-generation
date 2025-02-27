WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
featured_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS feature_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        ci.nr_order = 1 OR ci.nr_order IS NULL 
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 2
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
filtered_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM 
        ranked_movies rm
    JOIN 
        movie_keywords mk ON rm.title_id = mk.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    f.actor_id,
    f.name AS featured_actor,
    COUNT(DISTINCT fm.title_id) AS movies_as_lead,
    MAX(fm.production_year) AS latest_movie_year,
    COALESCE(SUM(CASE WHEN mk.keywords ILIKE '%action%' THEN 1 ELSE 0 END), 0) AS action_movies,
    COALESCE(SUM(CASE WHEN mk.keywords ILIKE '%drama%' THEN 1 ELSE 0 END), 0) AS drama_movies
FROM 
    featured_actors f
LEFT JOIN 
    filtered_movies fm ON fm.keywords ILIKE '%' || f.name || '%'
LEFT JOIN 
    movie_keywords mk ON fm.title_id = mk.movie_id
WHERE 
    f.feature_count > 2
GROUP BY 
    f.actor_id, f.name
ORDER BY 
    movies_as_lead DESC, latest_movie_year DESC
LIMIT 10;
