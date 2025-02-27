WITH MovieDetails AS (
    SELECT t.id as movie_id, 
           t.title, 
           t.production_year,
           COUNT(DISTINCT c.person_id) AS cast_count,
           STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM aka_title t
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN cast_info c ON c.movie_id = t.id
    LEFT JOIN aka_name a ON a.person_id = c.person_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year
), 
CompanyDetails AS (
    SELECT mc.movie_id, 
           COUNT(DISTINCT cn.id) AS company_count,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    GROUP BY mc.movie_id
),
KeywordDetails AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_count,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
)
SELECT md.movie_id,
       md.title,
       md.production_year,
       COALESCE(md.cast_count, 0) AS cast_count,
       COALESCE(md.cast_names, 'No Cast') AS cast_names,
       COALESCE(cd.company_count, 0) AS company_count,
       COALESCE(cd.companies, 'No Companies') AS companies,
       COALESCE(kd.keyword_count, 0) AS keyword_count,
       COALESCE(kd.keywords, 'No Keywords') AS keywords
FROM MovieDetails md
LEFT JOIN CompanyDetails cd ON cd.movie_id = md.movie_id
LEFT JOIN KeywordDetails kd ON kd.movie_id = md.movie_id
WHERE (md.cast_count > 5 OR md.production_year = 2023)
ORDER BY md.production_year DESC, md.movie_id ASC;
