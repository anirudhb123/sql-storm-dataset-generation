WITH movie_ratings AS (
    SELECT 
        mt.title, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(r.rating) AS avg_rating
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            rating 
        FROM 
            movie_ratings 
        WHERE 
            rating IS NOT NULL) r ON mt.movie_id = r.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title
),
filtered_movies AS (
    SELECT 
        title, 
        actor_count, 
        avg_rating,
        ROW_NUMBER() OVER (PARTITION BY actor_count ORDER BY avg_rating DESC) AS rank
    FROM 
        movie_ratings
    WHERE 
        avg_rating IS NOT NULL
)

SELECT 
    fm.title, 
    fm.actor_count, 
    fm.avg_rating
FROM 
    filtered_movies fm
WHERE 
    rank <= 10
ORDER BY 
    fm.actor_count DESC, 
    fm.avg_rating DESC;

WITH keyword_movies AS (
    SELECT 
        mt.title, 
        k.keyword 
    FROM 
        aka_title mt
    INNER JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
), 
company_movies AS (
    SELECT 
        mt.title, 
        cn.name AS company_name
    FROM 
        aka_title mt
    INNER JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
)

SELECT 
    km.title AS movie_title, 
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords, 
    STRING_AGG(DISTINCT cm.company_name, ', ') AS production_companies
FROM 
    keyword_movies km
LEFT JOIN 
    company_movies cm ON km.title = cm.title
GROUP BY 
    km.title
HAVING 
    COUNT(DISTINCT km.keyword) > 1;

SELECT 
    n.name, 
    COUNT(DISTINCT c.movie_id) AS movies_count,
    COUNT(DISTINCT ci.person_id) AS character_count
FROM 
    name n
LEFT JOIN 
    cast_info ci ON n.imdb_id = ci.person_id
LEFT JOIN 
    complete_cast c ON ci.movie_id = c.movie_id
WHERE 
    n.gender = 'F'
GROUP BY 
    n.name
HAVING 
    movies_count > 5
    AND character_count IS NOT NULL
ORDER BY 
    movies_count DESC
LIMIT 20;
