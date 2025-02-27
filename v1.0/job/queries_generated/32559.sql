WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        0 AS depth
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000

    UNION ALL

    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ah.depth + 1
    FROM 
        actor_hierarchy ah
    INNER JOIN 
        cast_info ci ON ah.actor_id = ci.person_id
    INNER JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year >= 1990 AND ah.depth < 3
),

keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    DISTINCT a.actor_name,
    at.title,
    at.production_year,
    k.keyword_total,
    CASE 
        WHEN at.production_year IS NULL THEN 'Unknown Year'
        ELSE to_char(at.production_year, '9999')
    END AS formatted_year,
    ROW_NUMBER() OVER (PARTITION BY a.actor_name ORDER BY k.keyword_total DESC) AS actor_rank
FROM 
    actor_hierarchy a
JOIN 
    cast_info ci ON a.actor_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    keyword_count k ON at.id = k.movie_id
WHERE 
    a.depth < 2
    AND (at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') OR at.kind_id IS NULL)
ORDER BY 
    a.actor_name, k.keyword_total DESC;

-- The query retrieves actors who acted in movies produced from 2000 onward,
-- listing their names alongside movie titles, production years, keyword counts,
-- and ranks them based on the number of associated keywords,
-- including robust handling of NULL production years and filtering
-- through correlated subqueries, including a recursive CTE for actor hierarchy.
