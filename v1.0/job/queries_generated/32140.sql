WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS depth
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    
    UNION ALL
    
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ch.depth + 1
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN CompanyHierarchy ch ON mc.movie_id = ch.movie_id
)
, RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_notes_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_notes_count,
    ch.company_name,
    ch.company_type,
    COALESCE(NULLIF(rm.production_year, 0), 'Unknown Year') AS year_info,
    CASE 
        WHEN rm.total_cast > 10 THEN 'Large Cast'
        WHEN rm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM RankedMovies rm
LEFT JOIN CompanyHierarchy ch ON rm.production_year = ch.depth
WHERE rm.movie_rank <= 5
ORDER BY rm.production_year DESC, rm.total_cast DESC;
