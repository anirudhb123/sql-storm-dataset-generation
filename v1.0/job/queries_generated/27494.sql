WITH processed_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ak.name AS aka_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN aka_title ak ON ak.movie_id = t.id
    WHERE t.production_year >= 2000
      AND k.keyword IS NOT NULL
),
combined_cast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name n ON ci.person_id = n.person_id
    JOIN movie_companies mc ON ci.movie_id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY ci.movie_id
),
final_results AS (
    SELECT 
        pt.title,
        pt.production_year,
        pt.keyword,
        cc.company_names,
        cc.cast_names
    FROM processed_titles pt
    JOIN combined_cast cc ON pt.title_id = cc.movie_id
)
SELECT 
    title, 
    production_year, 
    keyword,
    company_names,
    cast_names
FROM final_results
ORDER BY production_year DESC, title;
