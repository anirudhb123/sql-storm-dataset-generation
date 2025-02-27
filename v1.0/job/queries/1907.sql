
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_titles AS (
    SELECT 
        c.person_id, 
        t.id AS title_id, 
        t.title, 
        t.production_year
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.note IS NULL
),
company_movies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_details AS (
    SELECT 
        a.title, 
        a.production_year, 
        STRING_AGG(DISTINCT act.person_id::TEXT, ', ') AS actor_ids,
        STRING_AGG(DISTINCT comp.company_name, ', ') AS companies,
        RANK() OVER (ORDER BY a.production_year DESC) AS year_rank
    FROM 
        ranked_titles a
    LEFT JOIN 
        actor_titles act ON a.title_id = act.title_id
    LEFT JOIN 
        company_movies comp ON a.title_id = comp.movie_id
    GROUP BY 
        a.title, a.production_year
)
SELECT 
    md.title, 
    md.production_year,
    md.actor_ids,
    md.companies,
    CASE 
        WHEN md.year_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS production_group
FROM 
    movie_details md
WHERE 
    md.actor_ids IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
