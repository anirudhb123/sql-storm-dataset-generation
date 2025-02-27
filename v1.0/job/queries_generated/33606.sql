WITH RECURSIVE CastHierarchy AS (
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        1 AS depth 
    FROM cast_info ci
    UNION ALL
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        ch.depth + 1 
    FROM cast_info ci
    JOIN CastHierarchy ch ON ci.movie_id = ch.movie_id
    WHERE ci.person_id != ch.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_order
    FROM title t
    LEFT JOIN aka_title ak ON ak.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
    GROUP BY mc.movie_id, cn.name, ct.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.total_cast,
    md.cast_with_order,
    ci.company_name,
    ci.company_type,
    COALESCE(ch.depth, 0) AS max_cast_depth,
    COUNT(DISTINCT mk.keyword) AS total_keywords
FROM MovieDetails md
LEFT JOIN CompanyInfo ci ON ci.movie_id = md.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = md.movie_id
LEFT JOIN CastHierarchy ch ON ch.movie_id = md.movie_id
WHERE md.production_year >= 2000
GROUP BY 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.aka_names,
    md.total_cast, 
    md.cast_with_order, 
    ci.company_name, 
    ci.company_type, 
    ch.depth
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
