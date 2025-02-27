WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order = 1  -- Starting from the first role of each actor

    UNION ALL

    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.depth + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.movie_id = ci.movie_id AND ah.person_id <> ci.person_id 
    WHERE 
        ci.nr_order > 1 -- Consider subsequent roles to build the hierarchy
),

movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_info
    FROM 
        aka_title at
    JOIN 
        title t ON at.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id      -- link to actor names
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id        -- link to companies involved
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
),

final_benchmark AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actor_names,
        md.company_count,
        md.awards_info,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC, md.title ASC) AS rank
    FROM 
        movie_details md
    WHERE 
        md.production_year IS NOT NULL
)

SELECT 
    fb.title,
    fb.production_year,
    fb.actor_names,
    COALESCE(fb.company_count, 0) AS company_count,
    CASE 
        WHEN fb.awards_info > 0 THEN 'Award Winning' 
        ELSE 'Not Award Winning' 
    END AS award_status,
    fb.rank
FROM 
    final_benchmark fb
WHERE 
    fb.rank <= 5      -- Only top 5 movies each year
ORDER BY 
    fb.production_year DESC, 
    fb.rank;
