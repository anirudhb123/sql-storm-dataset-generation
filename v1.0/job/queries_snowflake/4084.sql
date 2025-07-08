
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
top_actors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
actor_details AS (
    SELECT 
        n.name,
        a.movie_id,
        a.note,
        a.nr_order
    FROM 
        cast_info a
    JOIN 
        top_actors t ON a.person_id = t.person_id
    JOIN 
        aka_name n ON a.person_id = n.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    COALESCE(ad.name, 'No Actor') AS actor_name,
    ad.note AS actor_note,
    ad.nr_order
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.title = (SELECT MAX(title) FROM aka_title WHERE id = ad.movie_id)
WHERE 
    rm.rank_year <= 3
ORDER BY 
    rm.production_year DESC,
    rm.title,
    ad.nr_order;
