
WITH MovieInfo AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT ka.name, ', ') WITHIN GROUP (ORDER BY ka.name) AS cast_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        mt.id AS movie_id
    FROM aka_title mt
    JOIN complete_cast cc ON mt.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN movie_keyword mw ON mt.id = mw.movie_id
    LEFT JOIN keyword kw ON mw.keyword_id = kw.id
    WHERE mt.production_year >= 2000
    GROUP BY mt.title, mt.production_year, mt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
),
FinalOutput AS (
    SELECT 
        mi.movie_title,
        mi.production_year,
        mi.cast_names,
        mi.keywords,
        COALESCE(ci.companies, 'No Companies') AS companies,
        COALESCE(ci.company_type, 'N/A') AS company_type
    FROM MovieInfo mi
    LEFT JOIN CompanyInfo ci ON mi.movie_id = ci.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    keywords,
    companies,
    company_type
FROM FinalOutput
ORDER BY production_year DESC, movie_title;
