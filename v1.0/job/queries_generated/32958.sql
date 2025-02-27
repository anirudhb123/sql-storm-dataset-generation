WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name,
        a.surname_pcode,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year = 2023)
    
    UNION ALL

    SELECT 
        ci.person_id,
        a.name,
        a.surname_pcode,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON ci.movie_id = ah.person_id
),
filtered_movies AS (
    SELECT 
        at.title,
        at.production_year,
        mu.company_id,
        mu.note AS company_note,
        ROW_NUMBER() OVER (PARTITION BY at.movie_id ORDER BY coalesce(mu.company_type_id, 0)) AS company_rank,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mu ON at.id = mu.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        at.title, at.production_year, mu.company_id, mu.note
    HAVING 
        COUNT(DISTINCT mk.keyword_id) > 2
),
final_selection AS (
    SELECT 
        hm.name AS actor_name,
        fm.title AS movie_title,
        fm.production_year,
        fm.company_note,
        ROW_NUMBER() OVER (PARTITION BY hm.person_id ORDER BY fm.production_year DESC) AS movie_rank
    FROM 
        actor_hierarchy hm
    JOIN 
        filtered_movies fm ON hm.person_id = fm.company_id
    WHERE 
        hm.surname_pcode IS NOT NULL
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.production_year,
    f.company_note,
    CASE 
        WHEN f.movie_rank = 1 THEN 'Latest Film'
        ELSE 'Previous Films'
    END AS film_status
FROM 
    final_selection f
WHERE 
    f.company_note IS NOT NULL
ORDER BY 
    f.production_year DESC, f.actor_name;
