WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
highly_rated_movies AS (
    SELECT 
        DISTINCT t.id AS movie_id,
        t.title,
        AVG(rating.rating) AS avg_rating
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        (SELECT movie_id, COUNT(*) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) AS rating ON t.id = rating.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
    HAVING 
        AVG(rating.rating) IS NOT NULL
), 
joined_data AS (
    SELECT 
        n.name AS actor_name,
        t.title AS movie_title,
        cm.kind AS company_type,
        km.keyword AS movie_keyword,
        hm.avg_rating
    FROM 
        aka_name n
    JOIN 
        cast_info ci ON n.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    LEFT JOIN 
        highly_rated_movies hm ON t.id = hm.movie_id
    WHERE 
        n.name IS NOT NULL AND
        (km.keyword LIKE '%action%' OR km.keyword LIKE '%drama%')
)
SELECT 
    j.actor_name,
    j.movie_title,
    j.company_type,
    j.movie_keyword,
    j.avg_rating
FROM 
    joined_data j
WHERE 
    j.avg_rating > 3.5
ORDER BY 
    j.avg_rating DESC, j.actor_name;
