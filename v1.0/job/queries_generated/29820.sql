WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_info,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN person_info pi ON c.person_id = pi.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, k.keyword
),
RankedMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year, 
        keyword, 
        cast_names, 
        company_names, 
        person_info, 
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS ranking
    FROM MovieDetails
)
SELECT 
    title_id,
    title,
    production_year,
    keyword,
    cast_names,
    company_names,
    person_info,
    company_count
FROM RankedMovies
WHERE ranking <= 5
ORDER BY production_year, company_count DESC;
