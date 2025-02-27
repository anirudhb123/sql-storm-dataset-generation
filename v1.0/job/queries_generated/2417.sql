WITH MovieStats AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(nt.gender = 'F') AS female_percentage,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    LEFT JOIN name nt ON pi.person_id = nt.id
    WHERE at.production_year > 2000
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.female_percentage,
        ms.total_companies,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.total_cast DESC) AS rn
    FROM MovieStats ms
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.female_percentage,
    CASE 
        WHEN tm.total_companies IS NULL THEN 'No Companies'
        ELSE tm.total_companies::text
    END AS company_count
FROM TopMovies tm
WHERE tm.rn <= 5
ORDER BY tm.production_year DESC, tm.total_cast DESC;

-- Include movie keywords for the top movies selected
UNION ALL

SELECT 
    at.title AS movie_title,
    at.production_year,
    NULL AS total_cast,
    NULL AS female_percentage,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM aka_title at
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
WHERE at.production_year > 2000
GROUP BY at.id, at.title, at.production_year
HAVING COUNT(DISTINCT mk.keyword_id) > 5
ORDER BY at.production_year DESC;

-- Subquery to calculate the number of movies per company
WITH CompanyMovieCount AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM company_name cn
    LEFT JOIN movie_companies mc ON cn.id = mc.company_id
    GROUP BY cn.id, cn.name
)

SELECT 
    cmm.company_name,
    cmm.movie_count,
    CASE 
        WHEN cmm.movie_count > 10 THEN 'Top Producer'
        ELSE 'Small Player'
    END AS company_size
FROM CompanyMovieCount cmm
WHERE cmm.movie_count > 0
ORDER BY cmm.movie_count DESC;
