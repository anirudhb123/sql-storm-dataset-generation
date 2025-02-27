WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.id) OVER (PARTITION BY t.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_within_year
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
recent_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        total_cast,
        rank_within_year
    FROM 
        ranked_movies
    WHERE 
        production_year IN (SELECT DISTINCT production_year FROM ranked_movies ORDER BY production_year DESC LIMIT 5)
),
selected_actors AS (
    SELECT 
        a.person_id,
        a.name,
        MIN(ci.nr_order) AS first_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.id) > 2
),
movies_with_actors AS (
    SELECT 
        r.title,
        r.production_year,
        r.total_cast,
        a.name AS actor_name,
        coalesce(ci.note, 'No role description') AS role_description
    FROM 
        recent_movies r
    LEFT JOIN 
        cast_info ci ON r.title_id = ci.movie_id
    LEFT JOIN 
        selected_actors a ON ci.person_id = a.person_id
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    m.actor_name,
    m.role_description
FROM 
    movies_with_actors m
WHERE 
    m.total_cast >= 3 
    AND (m.role_description LIKE '%hero%' OR m.role_description IS NULL)
ORDER BY 
    m.production_year DESC, m.title ASC
LIMIT 10
OFFSET 0
UNION
SELECT 
    t.title, 
    t.production_year, 
    COUNT(DISTINCT c.id) AS total_cast,
    'Unknown' AS actor_name,
    'Undisclosed role' AS role_description
FROM 
    title t
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
WHERE 
    t.production_year < 2000
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.id) < 2
ORDER BY 
    t.production_year DESC
LIMIT 5;

This query involves several advanced SQL concepts:
- Common Table Expressions (CTEs) are used to create easily digestible slices of complex queries.
- The query counts the number of cast members per movie and ranks movies within production years.
- It filters for movies with a sufficient number of cast members and explores actor information.
- It combines results using a UNION operator, one part focusing on recent movies with a substantial cast and an alternative part focusing on older, less populated titles.
- The use of `COALESCE` to handle potential NULL values ensures no data is lost due to missing information.
- A mix of JOIN types and correlated filtering offers insights into both popular and obscure titles, employing intricate predicates for selection.
