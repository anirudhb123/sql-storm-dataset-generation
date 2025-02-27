WITH actor_movie_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id
),
high_rating_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        AVG(r.rating) AS avg_rating
    FROM aka_title m
    JOIN reviews r ON m.id = r.movie_id
    GROUP BY m.id
    HAVING AVG(r.rating) > 8.0
),
popular_actors AS (
    SELECT 
        amc.person_id,
        amc.movie_count
    FROM actor_movie_counts amc
    WHERE amc.movie_count > 10
),
actors_with_titles AS (
    SELECT 
        p.person_id,
        p.name,
        t.title,
        t.production_year
    FROM aka_name p
    JOIN cast_info c ON p.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
)
SELECT 
    a.person_id,
    a.name,
    COUNT(DISTINCT t.movie_id) AS total_movies,
    SUM(CASE WHEN t.production_year >= 2000 THEN 1 ELSE 0 END) AS modern_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    'Overall Rating: ' || COALESCE(AVG(hm.avg_rating), 'Not Available') AS overall_rating
FROM actors_with_titles a
LEFT JOIN movie_keyword mk ON a.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN high_rating_movies hm ON a.movie_id = hm.movie_id
WHERE a.person_id IN (SELECT person_id FROM popular_actors)
GROUP BY a.person_id, a.name
HAVING COUNT(DISTINCT t.movie_id) > 5
ORDER BY total_movies DESC, overall_rating ASC;
