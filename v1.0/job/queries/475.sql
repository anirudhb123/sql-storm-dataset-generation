WITH MovieRanking AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
RecentMovies AS (
    SELECT 
        m.title, 
        m.production_year, 
        COALESCE(mr.actor_count, 0) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        MovieRanking mr ON m.title = mr.title
    WHERE 
        m.production_year >= (SELECT MAX(production_year) - 5 FROM title) 
)
SELECT 
    r.title, 
    r.production_year, 
    r.actor_count,
    CASE 
        WHEN r.actor_count > 5 THEN 'Popular'
        WHEN r.actor_count = 0 THEN 'No Cast'
        ELSE 'Moderate' 
    END AS popularity_category
FROM 
    RecentMovies r
WHERE 
    (r.actor_count IS NOT NULL AND r.actor_count < 10) OR r.actor_count = 0
ORDER BY 
    r.production_year DESC, 
    r.actor_count ASC;
