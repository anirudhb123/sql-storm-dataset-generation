WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COALESCE(kd.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.companies, 'No Companies') AS companies,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS year_rank
FROM MovieDetails md
LEFT JOIN KeywordDetails kd ON md.production_year = kd.movie_id
LEFT JOIN CompanyDetails cd ON md.production_year = cd.movie_id
WHERE md.production_year BETWEEN 1990 AND 2020
ORDER BY md.production_year, md.total_cast DESC;
