
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CastRoleCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT role_id) AS distinct_roles
    FROM 
        cast_info
    GROUP BY 
        movie_id
),
KeyWordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_names,
    rm.cast_count,
    crc.distinct_roles,
    kwc.keyword_count
FROM 
    RankedMovies rm
JOIN 
    CastRoleCount crc ON rm.movie_id = crc.movie_id
JOIN 
    KeyWordCount kwc ON rm.movie_id = kwc.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC,
    kwc.keyword_count DESC;
