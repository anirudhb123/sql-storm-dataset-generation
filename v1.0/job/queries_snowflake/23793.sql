
WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
person_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, ci.movie_id, rt.role
),
company_movie AS (
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
    WHERE 
        LOWER(cn.country_code) LIKE '%usa%'
),
keyword_movie AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
films_with_role AS (
    SELECT 
        rt.movie_id,
        rt.role_name,
        SUM(rt.role_count) AS total_roles
    FROM 
        person_roles rt
    WHERE 
        rt.role_name IS NOT NULL
    GROUP BY 
        rt.movie_id, rt.role_name
),
final_result AS (
    SELECT DISTINCT
        rt.title_id,
        rt.title,
        rt.production_year,
        cm.company_name,
        cm.company_type,
        kw.keywords,
        fr.role_name,
        fr.total_roles
    FROM 
        ranked_titles rt
    LEFT JOIN 
        company_movie cm ON rt.title_id = cm.movie_id
    LEFT JOIN 
        keyword_movie kw ON rt.title_id = kw.movie_id
    LEFT JOIN 
        films_with_role fr ON rt.title_id = fr.movie_id
    WHERE 
        rt.title_rank <= 10
        AND (fr.role_name IS NULL OR fr.total_roles > 1)
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    COALESCE(f.company_name, 'Independent') AS company_name,
    COALESCE(f.company_type, 'Not Specified') AS company_type,
    COALESCE(f.keywords, 'No keywords') AS keywords,
    f.role_name,
    COALESCE(f.total_roles, 0) AS total_roles,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Current'
    END AS era
FROM 
    final_result f
ORDER BY 
    f.production_year DESC, f.title;
