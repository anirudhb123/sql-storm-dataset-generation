
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id, 
        ki.keyword AS actor_keyword, 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ci.nr_order < 10
),
actor_summary AS (
    SELECT 
        ah.person_id,
        COUNT(*) AS movie_count,
        LISTAGG(DISTINCT ah.movie_title, ', ') WITHIN GROUP (ORDER BY ah.movie_title) AS movie_titles,
        MAX(ah.production_year) AS latest_movie_year
    FROM 
        actor_hierarchy ah
    GROUP BY 
        ah.person_id
),
null_company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(c.name, 'Unknown Company') AS safe_company_name
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
final_output AS (
    SELECT 
        asum.person_id,
        asum.movie_count,
        asum.movie_titles,
        nci.safe_company_name,
        nci.company_type,
        asum.latest_movie_year,
        CASE 
            WHEN asum.latest_movie_year IS NULL THEN 'No movies found'
            WHEN asum.movie_count < 5 THEN 'Fewer movies'
            ELSE 'Many movies'
        END AS engagement_level
    FROM 
        actor_summary asum
    LEFT JOIN 
        null_company_info nci ON asum.person_id = (SELECT person_id FROM cast_info WHERE movie_id = nci.movie_id LIMIT 1)
)
SELECT 
    *,
    COUNT(*) OVER (PARTITION BY engagement_level) AS engagement_level_count
FROM 
    final_output
WHERE 
    engagement_level = 'Many movies'
ORDER BY 
    latest_movie_year DESC
LIMIT 10;
