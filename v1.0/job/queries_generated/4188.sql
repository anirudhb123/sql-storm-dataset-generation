WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        (
            SELECT COUNT(*)
            FROM cast_info ci
            WHERE ci.person_id = a.person_id
        ) AS movie_count,
        (
            SELECT STRING_AGG(DISTINCT c.kind, ', ')
            FROM comp_cast_type c
            JOIN cast_info ci ON ci.role_id = c.id
            WHERE ci.person_id = a.person_id
        ) AS roles
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    ai.movie_count,
    ai.roles
FROM 
    RankedTitles r
JOIN 
    ActorInfo ai ON r.aka_id = ai.actor_id
WHERE 
    r.year_rank <= 3
ORDER BY 
    r.production_year DESC, r.actor_name ASC
UNION ALL
SELECT 
    'N/A' AS actor_name,
    t.title,
    t.production_year,
    0 AS movie_count,
    'Not Applicable' AS roles
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
WHERE 
    ci.id IS NULL AND t.production_year IS NOT NULL
ORDER BY production_year DESC;
