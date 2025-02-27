WITH Recursive MovieCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
        AND ak.name <> ''
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TitleInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ti.info AS additional_info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        info_type ti ON mi.info_type_id = ti.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ti.movie_id,
    ti.title,
    ti.production_year,
    ti.additional_info,
    coalesce(ca.actor_name, 'Unknown') AS actor_name,
    coalesce(mk.keywords, 'No keywords') AS movie_keywords,
    coalesce(comp.companies, 'No companies') AS production_companies,
    CASE 
        WHEN ci.company_count > 5 THEN 'Large Production'
        ELSE 'Small Production'
    END AS production_size,
    COUNT(DISTINCT CASE WHEN tk.kind_id IS NOT NULL THEN tk.kind_id END) AS unique_kinds
FROM 
    TitleInfo ti
LEFT JOIN 
    MovieCast ca ON ti.movie_id = ca.movie_id
LEFT JOIN 
    MovieKeywords mk ON ti.movie_id = mk.movie_id
LEFT JOIN 
    CompanyInfo comp ON ti.movie_id = comp.movie_id
LEFT JOIN 
    kind_type tk ON ti.kind_id = tk.id
GROUP BY 
    ti.movie_id, ti.title, ti.production_year, ti.additional_info, ci.company_count, ca.actor_name, mk.keywords, comp.companies
HAVING 
    COUNT(ca.actor_name) >= 2
ORDER BY 
    ti.production_year DESC, ti.title ASC
LIMIT 100;

