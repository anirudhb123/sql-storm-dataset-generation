
WITH movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON a.person_id = c.person_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year >= 2000
    GROUP BY m.id, m.title, m.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(ct.kind) AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
final_stats AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.actors,
        ms.keyword_count,
        ci.companies,
        ci.company_type
    FROM movie_stats ms
    LEFT JOIN company_info ci ON ms.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    actors,
    keyword_count,
    companies,
    company_type
FROM final_stats
WHERE total_cast > 5
ORDER BY production_year DESC, total_cast DESC
LIMIT 10;
