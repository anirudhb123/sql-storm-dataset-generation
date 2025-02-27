
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) DESC) AS rank,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM aka_title a
    JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN movie_companies m ON a.id = m.movie_id
    LEFT JOIN cast_info c ON c.movie_id = a.id
    WHERE a.production_year >= 2000 
    GROUP BY a.id, a.title, a.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(NULLIF(rm.company_count, 0), 1) AS effective_company_count,
    CASE 
        WHEN rm.rank = 1 THEN 'Top Movie'
        WHEN rm.rank <= 5 THEN 'Popular Movie'
        ELSE 'Other Movie'
    END AS movie_category,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM RankedMovies rm
LEFT JOIN aka_name ak ON ak.person_id IN (
    SELECT DISTINCT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = (
        SELECT movie_id 
        FROM movie_info 
        WHERE info LIKE 'has won%'
    )
)
WHERE rm.rank <= 10 
GROUP BY rm.title, rm.production_year, rm.rank, rm.company_count
HAVING COUNT(DISTINCT ak.id) > 0 
ORDER BY rm.production_year DESC, rm.rank;
