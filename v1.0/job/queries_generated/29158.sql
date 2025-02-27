WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.company_name,
    cd.company_type,
    mc.cast_names,
    rt.keyword
FROM RankedTitles rt
JOIN CompanyDetails cd ON rt.title_rank <= 5 AND rt.production_year = cd.movie_id
JOIN MovieCast mc ON rt.title_rank <= 5 AND mc.movie_id = rt.title_rank
WHERE rt.keyword IS NOT NULL
ORDER BY rt.production_year DESC, rt.title;
