
WITH MovieTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM aka_title a
    JOIN cast_info ci ON a.id = ci.movie_id
    JOIN aka_name c ON ci.person_id = c.person_id
    WHERE a.production_year BETWEEN 2000 AND 2023
    GROUP BY a.id, a.title, a.production_year, a.kind_id
),
KeywordGroups AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ct.kind AS company_types
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
)

SELECT 
    mt.title_id,
    mt.title,
    mt.production_year,
    mt.kind_id,
    mt.cast_names,
    kg.keywords,
    mci.companies,
    mci.company_types
FROM MovieTitles mt
LEFT JOIN KeywordGroups kg ON mt.title_id = kg.movie_id
LEFT JOIN MovieCompanyInfo mci ON mt.title_id = mci.movie_id
ORDER BY mt.production_year DESC, mt.title;
