
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
RecentMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    rm.movie_title,
    COALESCE(pa.name, 'Unknown') AS leading_actor,
    rm.production_year,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year not available'
        ELSE 'Released in ' || CAST(rm.production_year AS VARCHAR) 
    END AS release_message,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM 
    RecentMovies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name pa ON ci.person_id = pa.person_id AND ci.nr_order = 1
LEFT JOIN 
    movie_keyword mw ON rm.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
GROUP BY 
    rm.movie_title, pa.name, rm.production_year
HAVING 
    COUNT(DISTINCT kw.keyword) > 2
ORDER BY 
    rm.production_year DESC;
