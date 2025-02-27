WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.kind_id IS NOT NULL
),
person_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IS NOT NULL
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(CASE WHEN c.country_code IS NOT NULL THEN c.name ELSE 'Unknown' END, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_summary AS (
    SELECT 
        rt.title,
        rt.production_year,
        pr.person_id,
        pr.role,
        mci.company_names,
        mci.company_count,
        ki.keywords
    FROM 
        ranked_titles rt
    LEFT JOIN 
        person_roles pr ON pr.movie_id = rt.id
    LEFT JOIN 
        movie_company_info mci ON mci.movie_id = rt.id
    LEFT JOIN 
        keyword_info ki ON ki.movie_id = rt.id
)
SELECT 
    fs.title,
    fs.production_year,
    fs.person_id,
    fs.role,
    fs.company_names,
    fs.company_count,
    fs.keywords,
    CASE 
        WHEN fs.company_count IS NULL THEN 'No Companies'
        WHEN fs.company_count > 5 THEN 'Many Companies'
        ELSE 'Some Companies'
    END AS company_status,
    CONCAT(fs.title, ' - ', COALESCE(fs.keywords, 'No Keywords Found')) AS title_with_keywords
FROM 
    final_summary fs
WHERE 
    fs.production_year >= 2000
ORDER BY 
    fs.production_year DESC, fs.title ASC
LIMIT 100;

