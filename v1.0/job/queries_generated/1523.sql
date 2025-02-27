WITH MovieData AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN r.role = 'Actor' THEN ci.nr_order END) AS avg_actor_order
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
Keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.avg_actor_order,
    COALESCE(kw.keyword_list, 'No keywords') AS keywords,
    COALESCE(ci.company_name, 'Unknown Company') AS production_company,
    COALESCE(ci.company_type, 'Unknown Type') AS company_type
FROM MovieData md
LEFT JOIN Keywords kw ON md.title = kw.movie_id
LEFT JOIN CompanyInfo ci ON md.title = ci.movie_id
ORDER BY md.production_year DESC, md.cast_count DESC
LIMIT 100;
