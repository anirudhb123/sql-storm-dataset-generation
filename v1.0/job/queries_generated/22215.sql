WITH movie_rankings AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info c ON ak.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        ak.id IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
),
highly_active_actors AS (
    SELECT 
        ai.person_id,
        ai.name,
        ai.movie_count
    FROM 
        actor_info ai
    WHERE 
        ai.movie_count > 5
)
SELECT 
    title_id,
    title,
    production_year,
    COALESCE(h.actor_count_rank, 'N/A') AS actor_rank,
    STRING_AGG(DISTINCT aa.name, ', ') AS active_actors
FROM 
    movie_rankings h
LEFT JOIN 
    highly_active_actors aa ON h.title_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info c 
        WHERE 
            c.person_id = aa.person_id
    )
WHERE 
    h.actor_count_rank IS NOT NULL
GROUP BY 
    title_id, title, production_year, h.actor_count_rank
ORDER BY 
    production_year DESC, actor_rank DESC;

-- Include NULL logic and the peculiar nature of productions
WITH null_logic_demo AS (
    SELECT 
        t.title,
        COALESCE(m.note, 'No Note') AS movie_note,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.role_id IS NULL THEN 1 ELSE 0 END) AS null_roles
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 0 AND SUM(CASE WHEN c.role_id IS NULL THEN 1 ELSE 0 END) > 2
)
SELECT 
    title,
    movie_note,
    cast_count,
    null_roles
FROM 
    null_logic_demo
ORDER BY 
    cast_count DESC, title;

-- Final combined result incorporating set operators and window functions
SELECT 
    title,
    movie_note,
    c.cast_count
FROM 
    null_logic_demo c
UNION ALL
SELECT 
    h.title,
    CONCAT('Actor count ranked: ', h.actor_rank) AS movie_note,
    COUNT(DISTINCT aa.name) AS cast_count
FROM 
    movie_rankings h
LEFT JOIN 
    highly_active_actors aa ON h.title_id IN (
        SELECT 
            ca.movie_id 
        FROM 
            cast_info ca 
        WHERE 
            ca.person_id = aa.person_id
    )
WHERE 
    h.actor_rank IS NOT NULL
GROUP BY 
    h.title, h.actor_rank
ORDER BY 
    movie_note;
