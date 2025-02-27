WITH movie_summary AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(COUNT(ci.id), 0) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY t.id
),

info_summary AS (
    SELECT 
        ms.production_year,
        AVG(ms.cast_count) AS avg_cast_count,
        STRING_AGG(DISTINCT ms.title, ', ') AS titles,
        COUNT(DISTINCT ms.aka_names) AS aka_name_count,
        COUNT(DISTINCT ms.company_names) AS company_count,
        COUNT(DISTINCT ms.keywords) AS keyword_count
    FROM movie_summary ms
    GROUP BY ms.production_year
)

SELECT 
    is.production_year,
    is.avg_cast_count,
    is.titles,
    is.aka_name_count,
    is.company_count,
    is.keyword_count
FROM info_summary is
ORDER BY is.production_year DESC;
