
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
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
        a.name,
        COALESCE(ac.movie_count, 0) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ac.movie_count, 0) DESC) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_counts ac ON a.person_id = ac.person_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Year,
    a.name AS Actor_Name,
    a.movie_count AS Number_of_Movies,
    mw.keywords AS Associated_Keywords
FROM 
    ranked_titles t
JOIN 
    complete_cast cc ON t.title_id = cc.movie_id
JOIN 
    actor_details a ON cc.subject_id = a.actor_id
LEFT JOIN 
    movies_with_keywords mw ON t.title_id = mw.movie_id
WHERE 
    a.movie_count IS NOT NULL 
    AND (t.production_year = (SELECT MAX(production_year) FROM aka_title) OR a.movie_count > 5)
ORDER BY 
    t.production_year DESC, a.movie_count DESC;
