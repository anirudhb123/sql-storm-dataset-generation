WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        CASE 
            WHEN ci.nr_order IS NULL THEN 'Unordered'
            ELSE ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) 
        END AS role_order,
        t.title,
        t.production_year,
        t.kind_id
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
), 
MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(*) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
), 
MoviesWithInfo AS (
    SELECT 
        t.title,
        t.production_year,
        mci.company_type_id,
        MIN(mvi.info) AS general_info
    FROM title t
    INNER JOIN movie_info mvi ON t.id = mvi.movie_id
    LEFT JOIN movie_companies mci ON t.id = mci.movie_id
    WHERE mvi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Plot', 'Trivia'))
    GROUP BY t.title, t.production_year, mci.company_type_id
)
SELECT 
    ah.person_id,
    COUNT(DISTINCT ah.title) AS movies_count,
    COALESCE(mkc.keyword_count, 0) AS total_keywords,
    mw.title,
    mw.production_year,
    mw.general_info,
    STRING_AGG(DISTINCT cn.name, ', ') AS co_stars
FROM ActorHierarchy ah
LEFT JOIN MovieKeywordCount mkc ON ah.role_order = mkc.movie_id
JOIN MoviesWithInfo mw ON ah.title = mw.title AND ah.production_year = mw.production_year
LEFT JOIN cast_info ci ON ci.movie_id = mw.production_year
LEFT JOIN aka_name cn ON ci.person_id = cn.person_id
WHERE mw.company_type_id IS NOT NULL
GROUP BY ah.person_id, mw.title, mw.production_year, mw.company_type_id, mw.general_info
HAVING COUNT(DISTINCT ah.title) > 1
ORDER BY movies_count DESC, co_stars;
