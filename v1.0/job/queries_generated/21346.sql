WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year, 
        COALESCE(SUM(ci.nr_order), 0) AS total_cast_order,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COALESCE(SUM(ci.nr_order), 0) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
), 
actor_movie_count AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT ak.id) AS total_movies,
        MAX(CASE WHEN am.production_year = 2023 THEN am.movie_id END) AS latest_movie_id
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        ranked_movies am ON c.movie_id = am.movie_id
    GROUP BY 
        ak.person_id
), 
latest_actor_movies AS (
    SELECT 
        ak.name,
        am.title AS latest_title,
        am.production_year,
        a.total_movies
    FROM 
        aka_name ak
    JOIN 
        actor_movie_count a ON ak.person_id = a.person_id
    LEFT JOIN 
        ranked_movies am ON a.latest_movie_id = am.movie_id
    WHERE 
        a.total_movies > 5
)
SELECT 
    lam.name,
    lam.latest_title,
    COALESCE(lt.kind, 'UNKNOWN') AS title_kind,
    lam.production_year,
    lm.linked_movie_id,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN lam.production_year IS NULL OR lam.production_year < 2000 THEN 'Older Movie'
        WHEN lam.production_year >= 2000 AND lam.production_year <= 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM 
    latest_actor_movies lam
LEFT JOIN 
    movie_link lm ON lm.movie_id = lam.latest_movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = lam.latest_movie_id
LEFT JOIN 
    kind_type lt ON lam.latest_title = lt.kind
GROUP BY 
    lam.name, lam.latest_title, lam.production_year, lm.linked_movie_id, lt.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    lam.production_year DESC, lam.name ASC;
