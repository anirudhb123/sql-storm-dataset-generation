WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
EnhancedMovies AS (
    SELECT 
        rm.*,
        COALESCE(mo.info, 'N/A') AS movie_info,
        COALESCE(cn.name, 'Unknown Company') AS production_company
    FROM RankedMovies rm
    LEFT JOIN movie_info mo ON rm.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id 
),
FinalResults AS (
    SELECT 
        em.movie_id,
        em.title,
        em.production_year,
        em.cast_count,
        em.rank,
        LENGTH(em.movie_info) AS info_length,
        CASE 
            WHEN em.production_year < 2000 THEN 'Classic'
            WHEN em.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS movie_age,
        STRING_AGG(DISTINCT CONCAT('Keyword: ', kw.keyword), '; ') AS keywords
    FROM EnhancedMovies em
    LEFT JOIN movie_keyword mk ON em.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE em.cast_count > 1
    GROUP BY em.movie_id, em.title, em.production_year, em.rank, em.movie_info
)
SELECT 
    *,
    CASE 
        WHEN info_length IS NULL OR info_length = 0 THEN 'No Summary Available'
        ELSE movie_info 
    END AS display_info 
FROM FinalResults 
WHERE rank <= 5
ORDER BY production_year DESC, cast_count DESC;
