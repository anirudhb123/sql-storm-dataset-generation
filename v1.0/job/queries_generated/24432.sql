WITH RecursiveMovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(mt.production_year, 0) AS production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COALESCE(k.keyword, 'No Keywords')) AS keyword_rank
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
),
AggregatedProductionYears AS (
    SELECT 
        mm.movie_title,
        MAX(mm.production_year) AS max_production_year,
        COUNT(DISTINCT mm.actor_name) as actor_count
    FROM RecursiveMovieInfo mm
    GROUP BY mm.movie_title
),
TitleWithKeywordCounts AS (
    SELECT 
        m.movie_title,
        COUNT(DISTINCT k.keyword) AS unique_keyword_count
    FROM RecursiveMovieInfo m
    JOIN keyword k ON m.keyword = k.keyword
    GROUP BY m.movie_title
)
SELECT 
    ap.movie_title,
    ap.max_production_year,
    ap.actor_count,
    COALESCE(t.unique_keyword_count, 0) AS unique_keyword_count,
    CASE 
        WHEN ap.max_production_year < 2000 THEN 'Classic Era'
        WHEN ap.max_production_year BETWEEN 2000 AND 2010 THEN 'Early 21st Century'
        ELSE 'Recent Releases'
    END AS era_category
FROM AggregatedProductionYears ap
LEFT JOIN TitleWithKeywordCounts t ON ap.movie_title = t.movie_title
WHERE ap.actor_count > 1
ORDER BY ap.max_production_year DESC, ap.movie_title ASC
FETCH FIRST 50 ROWS ONLY;

-- A more obscure facet of the query using outer joins and NULL logic:
SELECT 
    title.id AS title_id,
    title.title AS title_name,
    COALESCE(NULLIF(ci.note, ''), 'No Role Notes') AS role_note,
    CASE 
        WHEN mt.production_year IS NULL THEN 'Year Unknown' 
        ELSE 'Year Available' 
    END AS year_status
FROM title
LEFT JOIN cast_info ci ON title.id = ci.movie_id
LEFT JOIN movie_info mi ON title.id = mi.movie_id AND (mi.info_type_id IS NULL OR mi.info IS NOT NULL)
LEFT JOIN aka_title mt ON title.id = mt.id
WHERE
    (mt.production_year IS NULL OR mt.production_year < 1990) 
    AND (LOWER(title.title) LIKE '%adventure%' OR title.title IS NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_companies mc
        WHERE mc.movie_id = title.id AND mc.company_type_id IS NULL
    )
ORDER BY title.title;
