
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        p.name AS person_name,
        a.name AS alias_name,
        r.role AS role_type
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN name p ON ci.person_id = p.id
    LEFT JOIN aka_name a ON p.id = a.person_id 
    LEFT JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year BETWEEN 2000 AND 2023 
      AND k.keyword ILIKE '%action%'
),
AggregateDetails AS (
    SELECT 
        md.movie_title,
        STRING_AGG(DISTINCT md.person_name, ', ') AS cast_names,
        STRING_AGG(DISTINCT CAST(md.production_year AS TEXT), ', ') AS production_years,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies_involved,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        COUNT(DISTINCT md.alias_name) AS total_aliases
    FROM MovieDetails md
    GROUP BY md.movie_title
    HAVING COUNT(DISTINCT md.person_name) > 5
)
SELECT 
    ad.movie_title, 
    ad.cast_names,
    ad.production_years,
    ad.companies_involved,
    ad.keywords,
    ad.total_aliases
FROM AggregateDetails ad
ORDER BY ad.movie_title;
