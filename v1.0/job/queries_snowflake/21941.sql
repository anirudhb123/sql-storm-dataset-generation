
WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS title_rank,
        COUNT(ci.person_id) AS cast_count,
        at.id AS movie_id
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.id, at.title, at.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(ri.companies, 'No Companies') AS companies,
        rt.cast_count,
        rt.title_rank
    FROM aka_title at
    LEFT JOIN RankedTitles rt ON at.id = rt.movie_id
    LEFT JOIN CompanyInfo ri ON at.id = ri.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.cast_count,
    md.title_rank
FROM MovieDetails md
WHERE 
    md.cast_count IS NOT NULL
    AND (md.production_year IS NOT NULL OR md.companies != 'No Companies')
ORDER BY 
    md.production_year DESC, 
    md.title_rank ASC
LIMIT 100;
