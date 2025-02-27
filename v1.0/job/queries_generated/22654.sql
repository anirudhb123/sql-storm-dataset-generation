WITH RECURSIVE titled_movies AS (
    SELECT 
        a.id AS title_id, 
        a.title, 
        a.production_year, 
        k.keyword 
    FROM 
        aka_title a 
    JOIN 
        movie_keyword mk ON mk.movie_id = a.id 
    JOIN 
        keyword k ON k.id = mk.keyword_id 
    WHERE 
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL

    UNION ALL

    SELECT 
        a.id AS title_id, 
        CONCAT(a.title, ' (Revised)') AS title, 
        a.production_year, 
        CONCAT('Revised: ', k.keyword) 
    FROM 
        aka_title a 
    JOIN 
        movie_keyword mk ON mk.movie_id = a.id 
    JOIN 
        keyword k ON k.id = mk.keyword_id 
    WHERE 
        a.production_year IS NULL
        OR a.title IS NULL
),
movie_company_info AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
top_casts AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order 
    FROM 
        cast_info ci 
    JOIN 
        aka_name a ON a.person_id = ci.person_id 
    WHERE 
        a.name IS NOT NULL
),
combined_info AS (
    SELECT 
        tm.title_id, 
        tm.title, 
        tm.production_year, 
        mc.company_count,
        mc.company_names,
        tc.actor_name,
        tc.actor_order
    FROM 
        titled_movies tm
    LEFT JOIN 
        movie_company_info mc ON mc.movie_id = tm.title_id
    LEFT JOIN 
        top_casts tc ON tc.movie_id = tm.title_id
)
SELECT 
    ci.title,
    ci.production_year,
    ci.company_count,
    ci.company_names,
    ci.actor_name,
    COALESCE(tc.actor_order, 0) AS actor_order,
    CASE 
        WHEN ci.actor_name IS NULL THEN 'No actor found'
        ELSE ci.actor_name
    END AS actor_info,
    (SELECT COUNT(*) FROM complete_cast WHERE movie_id = ci.title_id) AS complete_cast_count
FROM 
    combined_info ci
WHERE 
    ci.production_year >= 2000
ORDER BY 
    ci.production_year DESC, actor_order NULLS LAST;
