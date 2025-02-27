WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
),
noteworthy_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(p.keyword, 'No Keywords') AS keyword,
    na.name AS actor_name,
    na.movies_count
FROM 
    ranked_movies AS rm
LEFT JOIN 
    popular_keywords AS p ON rm.movie_id = p.movie_id
LEFT JOIN 
    noteworthy_actors AS na ON na.actor_id IN (SELECT person_id FROM cast_info WHERE movie_id = rm.movie_id)
WHERE 
    rm.year_rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC, 
    na.movies_count DESC
LIMIT 50;
