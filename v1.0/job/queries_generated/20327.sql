WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
person_movie_info AS (
    SELECT 
        p.person_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        AVG(CASE WHEN t.production_year >= 2000 THEN t.production_year ELSE NULL END) AS avg_modern_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        p.person_id, a.name
),
movie_company_info AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COUNT(mo.id) AS num_links
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    LEFT JOIN 
        movie_link mo ON m.movie_id = mo.movie_id
    GROUP BY 
        m.movie_id
),
null_check_titles AS (
    SELECT 
        id,
        title,
        CASE 
            WHEN title IS NULL THEN 'Untitled'
            ELSE title 
        END AS checked_title
    FROM 
        aka_title
),
final_results AS (
    SELECT 
        pm.actor_name,
        pm.movie_count,
        COALESCE(mt.title, 'No Title') AS title,
        mt.production_year,
        mci.company_names,
        mci.num_links
    FROM 
        person_movie_info pm
    LEFT JOIN 
        ranked_titles mt ON pm.movie_count >= 1 AND mt.title_rank <= pm.movie_count
    LEFT JOIN 
        movie_company_info mci ON mt.title_id = mci.movie_id
    WHERE 
        pm.avg_modern_year IS NOT NULL AND pm.movie_count > 0
)
SELECT 
    actor_name,
    title,
    production_year,
    company_names,
    CASE 
        WHEN num_links IS NULL THEN 'No Links'
        ELSE num_links::text || ' links'
    END AS link_info
FROM 
    final_results
ORDER BY 
    actor_name, production_year DESC
LIMIT 50;
