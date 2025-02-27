WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT k.id FROM kind_type k WHERE k.kind = 'movie')
),
distinct_actors AS (
    SELECT DISTINCT
        a.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        a.person_id, ak.name
),
movies_with_more_than_two_actors AS (
    SELECT 
        c.movie_id
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 2
),
company_count AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
final_results AS (
    SELECT 
        rt.title,
        rt.production_year,
        da.actor_name,
        cc.company_count,
        da.movie_count,
        COALESCE(cc.company_count, 0) AS company_count_coalesced
    FROM 
        ranked_titles rt
    LEFT JOIN 
        distinct_actors da ON rt.title_id = da.movie_count
    LEFT JOIN 
        company_count cc ON rt.title_id = cc.movie_id
    WHERE 
        rt.production_year IS NOT NULL
    AND 
        (cc.company_count IS NULL OR cc.company_count > 1)
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.company_count,
    CASE 
        WHEN f.movie_count IS NULL THEN 'No films available'
        ELSE 'Films count: ' || f.movie_count::text
    END AS film_statement,
    CASE 
        WHEN f.company_count IS NULL THEN 'No companies associated'
        ELSE 'Companies involved: ' || only_array_agg(DISTINCT f.company_count)::text
    END AS company_statement
FROM 
    final_results f
WHERE 
    f.production_year BETWEEN 2000 AND 2023
    AND (f.actor_name LIKE '%Smith%' OR f.actor_name IS NULL)
ORDER BY 
    f.production_year DESC, 
    f.title ASC;
