WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COALESCE(ac.movie_count, 0) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_counts ac ON a.person_id = ac.person_id
),
movies_with_keywords AS (
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
detailed_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mw.keywords, 'No keywords') AS keywords,
        CASE 
            WHEN t.production_year < 2000 THEN 'Classic'
            WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
            ELSE 'Contemporary'
        END AS movie_category
    FROM 
        ranked_titles t
    LEFT JOIN 
        movies_with_keywords mw ON t.title_id = mw.movie_id
    WHERE 
        t.rn = 1
),
actor_movie_info AS (
    SELECT 
        ad.actor_id,
        ad.actor_name,
        dm.title,
        dm.production_year,
        dm.keywords,
        dm.movie_category
    FROM 
        actor_details ad
    JOIN 
        cast_info ci ON ad.actor_id = ci.person_id
    JOIN 
        detailed_movies dm ON ci.movie_id = dm.title_id
    WHERE 
        ad.movie_count > 5 -- Only actors with more than 5 movies
)
SELECT 
    ami.actor_name,
    COUNT(DISTINCT ami.title) AS total_movies,
    AVG(EXTRACT(YEAR FROM age(DATE(ami.production_year || '-01-01'))) / 
    NULLIF(ami.movie_category::text = 'No keywords', TRUE)::int) AS avg_movie_age,
    STRING_AGG(DISTINCT ami.keywords, '; ') AS all_keywords
FROM 
    actor_movie_info ami
GROUP BY 
    ami.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;
