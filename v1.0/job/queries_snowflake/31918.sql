
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name,
        0 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        a.name,
        ah.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON ah.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        COUNT(c.id) AS total_cast,
        COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS has_note_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS unique_company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
combined AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        cd.companies,
        cd.unique_company_count,
        md.total_cast,
        md.has_note_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_within_year
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)

SELECT 
    combined.*,
    CASE 
        WHEN rank_within_year <= 3 THEN 'Top 3 in Year'
        ELSE 'Other'
    END AS rank_category,
    CASE 
        WHEN unique_company_count IS NULL THEN 'No companies'
        ELSE 'Companies involved'
    END AS company_status
FROM 
    combined
WHERE 
    actors IS NOT NULL
ORDER BY 
    production_year DESC, total_cast DESC;
