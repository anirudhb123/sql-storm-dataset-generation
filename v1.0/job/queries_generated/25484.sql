WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
company_details AS (
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
info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mii.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.id = mii.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    COALESCE(wk.keywords, 'No keywords') AS keywords,
    COALESCE(cd.company_name, 'No company information') AS production_company,
    COALESCE(cd.company_type, 'Unknown type') AS company_type,
    COALESCE(is.info_details, 'No additional info') AS additional_info
FROM 
    ranked_titles rt
LEFT JOIN 
    (SELECT movie_id, STRING_AGG(keyword, ', ') AS keywords FROM movies_with_keywords GROUP BY movie_id) wk ON rt.movie_title = wk.movie_title
LEFT JOIN 
    company_details cd ON rt.movie_title = cd.movie_id
LEFT JOIN 
    info_summary is ON rt.movie_title = is.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.actor_name, rt.production_year DESC;
