WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.movie_id IN (
            SELECT movie_id 
            FROM movie_info 
            WHERE info LIKE '%Oscar%'
        )
    UNION ALL
    SELECT 
        ci.person_id,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        actor_hierarchy ah ON ci.movie_id = ah.person_id
),
movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_order
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
final_results AS (
    SELECT 
        md.title,
        md.production_year,
        cs.company_count,
        cs.company_names,
        COUNT(DISTINCT ah.person_id) AS actor_count
    FROM 
        movie_details md
    LEFT JOIN 
        company_statistics cs ON md.production_year = cs.movie_id
    LEFT JOIN 
        actor_hierarchy ah ON md.title LIKE '%' || ah.person_id || '%'
    WHERE 
        (cs.company_count IS NULL OR cs.company_count > 3)
    GROUP BY 
        md.title, md.production_year, cs.company_count, cs.company_names
)
SELECT 
    title,
    production_year,
    company_count,
    company_names,
    actor_count,
    CASE 
        WHEN actor_count > 10 THEN 'Blockbuster'
        WHEN actor_count > 5 THEN 'Popular'
        ELSE 'Indie'
    END AS film_type
FROM 
    final_results
WHERE 
    actor_count > 0
ORDER BY 
    production_year DESC, actor_count DESC;
