WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) as title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keywords_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id
)
SELECT 
    a.name AS actor_name,
    am.movie_count,
    am.movie_titles,
    rt.title,
    rt.production_year,
    COALESCE(mkw.keywords_count, 0) AS keywords_count,
    CASE 
        WHEN am.movie_count >= 5 THEN 'Prolific Actor' 
        ELSE 'Less Active Actor' 
    END AS actor_activity
FROM 
    actor_movie_info am
JOIN 
    aka_name a ON am.person_id = a.person_id
JOIN 
    ranked_titles rt ON rt.title_rank <= 5
LEFT JOIN 
    movies_with_keywords mkw ON rt.id = mkw.movie_id
WHERE 
    rt.kind_id IS NOT NULL
    AND (rt.production_year = (SELECT MAX(production_year) FROM aka_title) OR rt.production_year IS NULL)
ORDER BY 
    a.name, rt.production_year DESC;
