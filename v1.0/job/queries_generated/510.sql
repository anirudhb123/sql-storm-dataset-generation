WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
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
incomplete_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COALESCE(am.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        title t
    LEFT JOIN 
        actor_movies am ON t.id = am.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    WHERE 
        t.production_year < 2000
)
SELECT 
    im.title,
    im.production_year,
    im.actor_count,
    im.keywords,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN 
        (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = t.id)) AS total_actors
FROM 
    incomplete_movies im
LEFT JOIN 
    title t ON im.title = t.title
WHERE 
    im.actor_count > (SELECT AVG(actor_count) FROM actor_movies)
ORDER BY 
    im.production_year DESC, 
    im.actor_count DESC
LIMIT 10;
