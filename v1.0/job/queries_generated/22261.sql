WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        c.kind AS company_kind,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_per_year
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name, 
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL AND
        a.name NOT LIKE '%unknown%'
    GROUP BY 
        a.person_id, a.name
),
CriticalInfo AS (
    SELECT 
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_info
    FROM 
        person_info pi
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'career%')
    GROUP BY 
        pi.person_id
)
SELECT 
    rt.title, 
    rt.production_year,
    fa.name AS actor_name,
    fa.movies_count,
    ci.person_info,
    COALESCE(rt.company_kind, 'Independent') AS production_company,
    CASE 
        WHEN fa.movies_count > 10 THEN 'Veteran Actor'
        WHEN fa.movies_count BETWEEN 5 AND 10 THEN 'Established Actor'
        ELSE 'Newcomer'
    END AS actor_category
FROM 
    RankedTitles rt
JOIN 
    FilteredActors fa ON rt.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = fa.person_id)
LEFT JOIN 
    CriticalInfo ci ON fa.person_id = ci.person_id
WHERE 
    rt.rank_per_year <= 5
    AND rt.production_year IS NOT NULL
    AND (rt.production_year < 2020 OR rt.company_kind IS NULL)
ORDER BY 
    rt.production_year DESC, 
    fa.movies_count DESC, 
    rt.title;
