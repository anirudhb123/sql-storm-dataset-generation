WITH actor_movies AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL AND
        a.name_pcode_nf IS NOT NULL
    GROUP BY 
        a.person_id
),
high_movie_count AS (
    SELECT 
        person_id
    FROM 
        actor_movies
    WHERE 
        movie_count >= 10
),
user_favorites AS (
    SELECT 
        u.user_id,
        STRING_AGG(DISTINCT t.title, ', ') AS favorite_titles
    FROM 
        user_likes u
    JOIN 
        movie_keyword mk ON u.favorite_keyword_id = mk.id
    JOIN 
        aka_title t ON mk.movie_id = t.id
    GROUP BY 
        u.user_id
),
recipient_info AS (
    SELECT 
        l.linked_movie_id,
        l.link_type_id,
        t.title,
        t.production_year
    FROM 
        movie_link l
    JOIN 
        aka_title t ON l.linked_movie_id = t.id
    WHERE 
        l.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    a.name,
    a.surname_pcode,
    am.movie_count,
    COALESCE(uf.favorite_titles, 'No Favorites') AS user_favorites,
    r.title AS linked_movie_title,
    r.production_year AS linked_movie_year
FROM 
    aka_name a
JOIN 
    actor_movies am ON a.person_id = am.person_id
LEFT JOIN 
    user_favorites uf ON uf.user_id = a.person_id
LEFT JOIN 
    recipient_info r ON r.linked_movie_id = am.movie_count
WHERE 
    a.name NOT LIKE '%test%' AND
    (a.md5sum IS NULL OR LENGTH(a.md5sum) < 30)
ORDER BY 
    am.movie_count DESC NULLS LAST, 
    a.name
LIMIT 50;

-- This SQL query leverages a combination of CTEs for structured data gathering, aggregation functions,
-- outer joins for optional data linking, and a complex WHERE clause to filter results based on unusual conditions.
