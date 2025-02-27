WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        CAST(COALESCE(m.title, 'Not Available') AS text) AS linked_movie_title,
        COALESCE(k.keyword, 'No Keywords') AS related_keyword,
        COUNT(DISTINCT c.person_id) AS total_cast_count
    FROM title t
    LEFT JOIN movie_link ml ON ml.movie_id = t.id
    LEFT JOIN title m ON ml.linked_movie_id = m.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON c.movie_id = t.id
    WHERE t.production_year BETWEEN 1990 AND 2020
    GROUP BY t.id, t.title, t.production_year, t.kind_id, m.title, k.keyword
), 
company_data AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS unique_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.kind_id,
    md.linked_movie_title,
    md.related_keyword,
    md.total_cast_count,
    COALESCE(cd.unique_companies, 0) AS unique_company_count,
    COALESCE(cd.company_names, 'No Companies') AS companies
FROM movie_data md
LEFT JOIN company_data cd ON md.id = cd.movie_id
ORDER BY md.production_year DESC, md.total_cast_count DESC, md.title ASC;
