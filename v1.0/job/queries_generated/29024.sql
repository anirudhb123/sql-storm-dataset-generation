WITH renamed_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        c.kind AS company_type,
        STRING_AGG(DISTINCT p.info, '; ') AS additional_info
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, a.name, c.kind
),

ranked_titles AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword,
        actor_name,
        company_type,
        additional_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(keyword) DESC) AS keyword_rank
    FROM 
        renamed_titles
    GROUP BY 
        title_id, title, production_year, keyword, actor_name, company_type, additional_info
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.keyword,
    rt.actor_name,
    rt.company_type,
    rt.additional_info
FROM 
    ranked_titles rt
WHERE 
    rt.keyword_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.keyword_rank ASC;
