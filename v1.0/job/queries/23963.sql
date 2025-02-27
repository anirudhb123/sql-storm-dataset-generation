
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year,
        SUM(CASE WHEN mi.info LIKE '%Top%' THEN 1 ELSE 0 END) AS top_info_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Genre%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
MaxCast AS (
    SELECT 
        production_year,
        MAX(cast_count) AS max_cast
    FROM 
        RankedMovies
    GROUP BY 
        production_year
    HAVING 
        MAX(cast_count) > 5
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.top_info_count
    FROM 
        RankedMovies rm
    JOIN 
        MaxCast mc ON rm.production_year = mc.production_year AND rm.cast_count = mc.max_cast
)
SELECT 
    sm.movie_id,
    sm.movie_title,
    sm.production_year,
    sm.cast_count,
    COALESCE(sm.top_info_count, 0) AS top_information_count,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_name ak 
     JOIN cast_info ci ON ak.person_id = ci.person_id 
     WHERE ci.movie_id = sm.movie_id) AS cast_names,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = sm.movie_id 
       AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')) AS action_keyword_count
FROM 
    SelectedMovies sm
WHERE 
    sm.top_info_count IS NOT NULL 
    OR EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = sm.movie_id AND mc.company_type_id IS NULL)
ORDER BY 
    sm.production_year DESC, 
    sm.cast_count DESC;
