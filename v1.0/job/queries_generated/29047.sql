WITH movie_title_keyword AS (
    SELECT
        title.id AS movie_id,
        title.title,
        ARRAY_AGG(DISTINCT keyword.keyword) AS keywords
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title
),
popular_actors AS (
    SELECT
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        title ON cast_info.movie_id = title.id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        aka_name.person_id, aka_name.name
    HAVING 
        COUNT(DISTINCT cast_info.movie_id) > 5
),
collaborations AS (
    SELECT
        c1.person_id AS actor1_id,
        c2.person_id AS actor2_id,
        COUNT(DISTINCT c1.movie_id) AS collaboration_count
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id != c2.person_id
    GROUP BY 
        c1.person_id, c2.person_id
    HAVING 
        collaboration_count > 1
)
SELECT 
    p.name AS actor_name,
    ARRAY_AGG(DISTINCT m.title) AS movies,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    (SELECT COUNT(DISTINCT ca.actor2_id) 
        FROM collaborations ca
        WHERE ca.actor1_id = p.person_id) AS co_actor_count
FROM 
    popular_actors p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    movie_title_keyword m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    p.person_id, p.name
ORDER BY 
    total_movies DESC, actor_name;
