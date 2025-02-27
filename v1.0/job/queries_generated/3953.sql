WITH movie_years AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
popular_titles AS (
    SELECT 
        mt.movie_id,
        mt.title,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        movie_companies mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.movie_id
    JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    GROUP BY 
        mt.movie_id, mt.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 10
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.person_id = a.person_id) AS total_movies
    FROM 
        aka_name a
),
movies_with_actors AS (
    SELECT 
        mt.movie_id,
        mt.title,
        COALESCE(ad.actor_id, -1) AS actor_id,
        ad.name AS actor_name,
        ad.total_movies
    FROM 
        popular_titles pt
    LEFT JOIN 
        cast_info ci ON pt.movie_id = ci.movie_id
    LEFT JOIN 
        actor_details ad ON ci.person_id = ad.actor_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.actor_name,
    mw.total_movies,
    my.production_year,
    CASE 
        WHEN mw.total_movies IS NULL THEN 'No data'
        WHEN mw.total_movies > 2 THEN 'Popular Actor'
        ELSE 'Less Known'
    END AS actor_popularity,
    RANK() OVER (PARTITION BY my.production_year ORDER BY mw.total_movies DESC) AS actor_rank
FROM 
    movies_with_actors mw
JOIN 
    movie_years my ON mw.movie_id = my.movie_id
ORDER BY 
    my.production_year DESC, actor_rank;
