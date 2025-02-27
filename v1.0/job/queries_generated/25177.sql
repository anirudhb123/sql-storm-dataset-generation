WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COALESCE(SUM(case when cc.kind = 'Production' then 1 else 0 end), 0) AS production_count,
        COALESCE(SUM(case when cc.kind = 'Distribution' then 1 else 0 end), 0) AS distribution_count
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN company_name com ON com.id = (
        SELECT mc.company_id
        FROM movie_companies mc
        WHERE mc.movie_id = t.id
        LIMIT 1
    )
    LEFT JOIN comp_cast_type cct ON ci.person_role_id = cct.id
    LEFT JOIN name n ON an.person_id = n.imdb_id
    LEFT JOIN aka_title at ON t.id = at.movie_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    movie_title,
    production_year,
    keywords,
    cast_names,
    production_count,
    distribution_count
FROM movie_details
ORDER BY production_year DESC;
