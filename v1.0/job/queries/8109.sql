
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword ON mk.keyword_id = keyword.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.cast,
        COUNT(mo.id) AS movie_info_count,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM MovieDetails md
    LEFT JOIN movie_info mo ON md.movie_id = mo.movie_id
    LEFT JOIN complete_cast cc ON md.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY md.movie_id, md.title, md.production_year, md.keywords, md.companies, md.cast
)
SELECT 
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.companies,
    mi.cast,
    mi.movie_info_count,
    mi.cast_count
FROM MovieInfo mi
WHERE mi.production_year >= 2000 AND mi.cast_count > 5
ORDER BY mi.production_year DESC, mi.movie_info_count DESC;
