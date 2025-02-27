
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank_by_keyword
    FROM aka_title at
    LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM RankedMovies rm
    WHERE rm.rank_by_company <= 5 OR rm.rank_by_keyword <= 5
),
CombinedInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        CASE 
            WHEN tm.company_count > 0 THEN 'Company present'
            ELSE 'No company present'
        END AS company_info,
        CASE 
            WHEN tm.keyword_count > 0 THEN 'Keywords present'
            ELSE 'No keywords present'
        END AS keyword_info,
        COALESCE(p.info, 'No info') AS person_details
    FROM TopMovies tm
    LEFT JOIN cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN person_info p ON ci.person_id = p.person_id
)
SELECT 
    ci.title,
    ci.production_year,
    ci.company_info,
    ci.keyword_info,
    STRING_AGG(DISTINCT ci.person_details, ', ') AS cast_info
FROM CombinedInfo ci
GROUP BY ci.title, ci.production_year, ci.company_info, ci.keyword_info
ORDER BY ci.production_year DESC, ci.company_info DESC;
