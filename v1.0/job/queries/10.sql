
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
AkaDetails AS (
    SELECT 
        a.person_id,
        STRING_AGG(a.name, ', ') AS aka_names
    FROM aka_name a
    GROUP BY a.person_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(p.name, ' as ', r.role) ORDER BY c.nr_order) AS cast_crew
    FROM cast_info c
    JOIN name p ON c.person_id = p.id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(ad.aka_names, 'No Alternate Names') AS alternate_names,
    COALESCE(cd.cast_crew, 'No Cast Info') AS cast_info,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mk.keyword_id) AS associated_keywords
FROM RankedTitles rt
LEFT JOIN AkaDetails ad ON rt.title_id = ad.person_id
LEFT JOIN CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN movie_companies mc ON rt.title_id = mc.movie_id
LEFT JOIN movie_keyword mk ON rt.title_id = mk.movie_id
WHERE rt.title IS NOT NULL
AND rt.title_rank <= 5
GROUP BY rt.title_id, rt.title, rt.production_year, ad.aka_names, cd.cast_crew
ORDER BY rt.production_year DESC, rt.title;
