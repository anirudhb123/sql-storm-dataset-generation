WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS title_name,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM title
    WHERE title.production_year IS NOT NULL
),
PopularKeywords AS (
    SELECT 
        movie_id,
        COUNT(keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
    HAVING COUNT(keyword_id) > 2
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title_name,
    rt.production_year,
    COUNT(DISTINCT ca.person_id) AS cast_count,
    cd.company_name,
    cd.company_type,
    pk.keyword_count
FROM RankedTitles rt
LEFT JOIN complete_cast cc ON rt.title_id = cc.movie_id
LEFT JOIN cast_info ca ON cc.id = ca.movie_id
LEFT JOIN CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN PopularKeywords pk ON rt.title_id = pk.movie_id
WHERE rt.year_rank <= 5
GROUP BY rt.title_name, rt.production_year, cd.company_name, cd.company_type, pk.keyword_count
ORDER BY rt.production_year DESC, cast_count DESC;
