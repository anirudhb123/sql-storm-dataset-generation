
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(ka.name, 'Unknown') AS main_actor_name,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id, ka.name
),

KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

EnhancedDetails AS (
    SELECT 
        md.*,
        kd.keywords,
        NTILE(5) OVER (PARTITION BY md.kind_id ORDER BY md.production_year DESC) AS production_year_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
)

SELECT
    ed.title,
    ed.production_year,
    ed.main_actor_name,
    ed.production_company_count,
    ed.keywords,
    CASE 
        WHEN ed.production_year_rank = 1 THEN 'Recent'
        WHEN ed.production_year_rank = 5 THEN 'Oldest'
        ELSE 'Mid Age'
    END AS age_category,
    CASE 
        WHEN ed.production_company_count IS NULL THEN 'No Production Company'
        ELSE CONCAT(ed.production_company_count, ' Companies')
    END AS company_info
FROM 
    EnhancedDetails ed
WHERE 
    (ed.production_year > 2000 OR ed.main_actor_name LIKE '%Smith%')
    AND (ed.keywords IS NULL OR ed.keywords LIKE '%Thriller%')
ORDER BY 
    ed.production_year DESC, ed.title;
