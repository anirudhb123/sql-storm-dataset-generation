WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS actor_count
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY
        t.title, t.production_year, a.name
),
MaxActorCount AS (
    SELECT 
        production_year,
        MAX(actor_count) AS max_count
    FROM 
        RankedMovies
    GROUP BY 
        production_year
),
FilteredTitles AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name,
        rm.actor_count
    FROM 
        RankedMovies rm
    JOIN 
        MaxActorCount mac ON rm.production_year = mac.production_year AND rm.actor_count = mac.max_count
    WHERE 
        (EXISTS (
            SELECT 1 
            FROM movie_keyword mk 
            WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title) 
            AND mk.keyword_id IN (
                SELECT id FROM keyword WHERE keyword LIKE 'comedy%'
            )
        ) OR 
        (SELECT COUNT(mk.id) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title)) > 2)
)
SELECT
    ft.title,
    ft.production_year,
    STRING_AGG(ft.actor_name, ', ') AS actors,
    CASE 
        WHEN ft.production_year < 2000 THEN 'Classic'
        WHEN ft.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    COALESCE(NULLIF(ft.actor_count, 0), -1) AS adjusted_actor_count
FROM 
    FilteredTitles ft
GROUP BY 
    ft.title, ft.production_year, ft.actor_count
ORDER BY 
    ft.production_year DESC, ft.title ASC;

-- Additional logic to demonstrate literal trickiness with NULLs and amusing outputs
WITH MovieStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT person_id) AS unique_actors,
        AVG(COALESCE(NULLIF(role_id, 0), 1)) AS avg_role_type
    FROM
        cast_info
    GROUP BY 
        movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(ms.unique_actors, 0) AS unique_actor_count,
    CASE 
        WHEN ms.avg_role_type < 1 THEN 'Unassigned Roles'
        WHEN ms.avg_role_type >= 1 AND ms.avg_role_type <= 2 THEN 'Minimalistic'
        ELSE 'Role Rich'
    END AS role_diversity
FROM
    aka_title m
LEFT JOIN 
    MovieStats ms ON m.id = ms.movie_id
ORDER BY 
    unique_actor_count DESC, m.title;

-- Further adding unusual NULL logic involving outer joins and peculiar string expressions
SELECT 
    a.name AS actor_name,
    COALESCE(b.title, 'Unknown Title') AS movie_title,
    CASE 
        WHEN b.title IS NULL THEN 'This movie has lost its title, how sad!'
        ELSE 'Title found: ' || b.title
    END AS title_status
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    aka_title b ON ci.movie_id = b.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.name;
