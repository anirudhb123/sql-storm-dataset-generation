WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS title_count
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
), 
CompanyStats AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.id) AS company_count, 
        MAX(ct.kind) AS max_company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
), 
PopularActors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        SUM(CASE WHEN at.production_year = 2022 THEN 1 ELSE 0 END) AS won_awards_count
    FROM cast_info c
    JOIN aka_title at ON c.movie_id = at.id
    WHERE c.note IS NOT NULL 
    GROUP BY c.person_id
    HAVING COUNT(DISTINCT c.movie_id) > 5
), 
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    cs.company_count,
    pa.movies_count AS actor_movies_count,
    pa.won_awards_count,
    dk.keywords
FROM RankedTitles rt
LEFT JOIN CompanyStats cs ON rt.production_year = cs.production_year
LEFT JOIN PopularActors pa ON pa.person_id IN (
    SELECT c.person_id 
    FROM cast_info c 
    JOIN aka_title at ON c.movie_id = at.id
    WHERE at.production_year = rt.production_year
)
LEFT JOIN DistinctKeywords dk ON rt.id = dk.movie_id
WHERE rt.title_rank = 1 AND rt.title_count >= (SELECT AVG(title_count) FROM RankedTitles)
  AND cs.company_count IS NOT NULL
ORDER BY rt.production_year DESC, rt.title;
