WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(mc.company_id) AS production_company_count,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.production_company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(CAST(SUBSTRING(tm.title FROM '[0-9]+') AS INTEGER), 0) AS title_number,
    (SELECT COUNT(ci.id) FROM cast_info ci 
     INNER JOIN aka_name an ON ci.person_id = an.person_id 
     WHERE ci.movie_id IN (SELECT movie_id FROM movie_info mi WHERE mi.info LIKE '%action%')) AS action_cast_count,
    (SELECT K.keyword 
     FROM movie_keyword mk 
     JOIN keyword K ON mk.keyword_id = K.id 
     WHERE mk.movie_id = tm.production_company_count) AS associated_keyword
FROM 
    TopMovies tm
WHERE 
    tm.production_company_count > 0
ORDER BY 
    tm.production_year DESC, 
    tm.production_company_count DESC
LIMIT 10;
