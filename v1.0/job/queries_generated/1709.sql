WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
actor_details AS (
    SELECT 
        a.id AS actor_id, 
        a.name, 
        a.md5sum,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name, a.md5sum
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
movie_info AS (
    SELECT 
        m.id AS movie_id,
        mi.info AS trivia
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.note IS NOT NULL
)
SELECT 
    pm.title,
    pm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.trivia, 'No trivia available') AS trivia
FROM 
    popular_movies pm
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
LEFT JOIN 
    actor_details ad ON ci.person_id = ad.actor_id
LEFT JOIN 
    movie_keywords mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON pm.movie_id = mi.movie_id
WHERE 
    (ad.movie_count > 1 OR ad.movie_count IS NULL)
ORDER BY 
    pm.production_year DESC, 
    ad.movie_count DESC;
