WITH actor_titles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%feature%')
), 
actor_summary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(*) AS total_movies,
        AVG(production_year) AS avg_year,
        MAX(production_year) AS latest_year
    FROM 
        actor_titles
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    asum.actor_name,
    asum.total_movies,
    asum.avg_year,
    asum.latest_year,
    STRING_AGG(DISTINCT at.movie_title, ', ') AS movie_titles,
    COALESCE(NULLIF(SUM(CASE WHEN asum.latest_year < 2000 THEN 1 ELSE 0 END), 0), -1) AS pre_2000_movies_count,
    CASE 
        WHEN asum.total_movies = 0 THEN 'No movies available'
        ELSE 'Movies available'
    END AS movie_availability
FROM 
    actor_summary asum
LEFT JOIN 
    actor_titles at ON asum.actor_id = at.actor_id AND at.title_rank <= 5
GROUP BY 
    asum.actor_id, asum.actor_name, asum.total_movies, asum.avg_year, asum.latest_year
HAVING 
    asum.total_movies > 2
ORDER BY 
    asum.total_movies DESC, asum.latest_year ASC;
