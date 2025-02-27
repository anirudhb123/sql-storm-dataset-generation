WITH Recursive_Actor_Movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) as rn
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
), Movie_Actor_Info AS (
    SELECT 
        am.person_id,
        am.title,
        am.production_year,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY am.person_id) AS total_movies,
        MAX(am.production_year) OVER (PARTITION BY am.person_id) AS last_movie_year,
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY am.person_id) > 5 THEN 'Frequent Actor'
            ELSE 'Occasional Actor'
        END AS actor_frequent
    FROM 
        Recursive_Actor_Movies am
    JOIN 
        aka_name a ON am.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
), Filtered_Movies AS (
    SELECT DISTINCT
        m.id AS movie_id,
        m.title,
        NULLIF(m.production_year, 0) AS production_year_adjusted,
        k.keyword AS movie_keyword
    FROM 
        aka_title m 
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL AND 
        m.production_year <= EXTRACT(YEAR FROM CURRENT_DATE) 
        AND (m.note IS NULL OR m.note NOT LIKE '%canceled%')
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year_adjusted,
    SUM(CASE WHEN a.actor_frequent = 'Frequent Actor' THEN 1 ELSE 0 END) AS frequent_actor_count,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actor_names,
    COUNT(DISTINCT CASE WHEN f.movie_keyword IS NOT NULL THEN f.movie_keyword END) AS keyword_count
FROM 
    Filtered_Movies f
LEFT JOIN 
    Movie_Actor_Info a ON f.title = a.title AND f.production_year_adjusted = a.production_year
GROUP BY 
    f.movie_id, f.title, f.production_year_adjusted
HAVING 
    COUNT(DISTINCT a.person_id) > 2 OR SUM(CASE WHEN a.actor_frequent = 'Frequent Actor' THEN 1 ELSE 0 END) > 0
ORDER BY 
    production_year_adjusted DESC NULLS LAST,
    frequent_actor_count DESC;
