WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS title_count
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
),
top_titles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.year_rank,
        rt.title_count
    FROM 
        ranked_titles rt
    WHERE 
        rt.year_rank <= 5
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN ci.person_role_id = (SELECT id FROM role_type WHERE role = 'lead') THEN 1 ELSE 0 END) AS has_lead_actor
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    cs.actor_count,
    CASE WHEN cs.has_lead_actor = 1 THEN 'Yes' ELSE 'No' END AS lead_actor,
    COALESCE(mci.note, 'No Note') AS company_note
FROM 
    top_titles tt
LEFT JOIN 
    complete_cast cc ON tt.title = (SELECT title FROM aka_title WHERE movie_id = cc.movie_id)
LEFT JOIN 
    cast_summary cs ON tt.production_year = (SELECT production_year FROM aka_title WHERE movie_id = cs.movie_id)
LEFT JOIN 
    movie_companies mci ON tt.production_year = (SELECT production_year FROM aka_title WHERE movie_id = mci.movie_id)
WHERE 
    tt.title_count > 1
ORDER BY 
    tt.production_year DESC, 
    tt.title;
