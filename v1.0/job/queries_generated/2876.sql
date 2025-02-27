WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
), 

CastCounts AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast 
    FROM 
        cast_info ci 
    GROUP BY 
        ci.movie_id
),

TopCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCounts cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.rank_per_year <= 10
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(cc.total_cast, 0) AS total_cast,
    (SELECT COUNT(DISTINCT m.id) 
     FROM movie_companies m 
     WHERE m.movie_id = t.movie_id 
     AND m.company_id IS NOT NULL 
     AND m.company_type_id = (SELECT id FROM company_type WHERE kind = 'Producer')) AS producer_count,
    CASE 
        WHEN t.production_year IS NOT NULL THEN CONCAT(t.title, ' was produced in ', t.production_year)
        ELSE 'Year unknown'
    END AS title_year
FROM 
    TopCastMovies t
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    t.total_cast >= (SELECT AVG(total_cast) FROM CastCounts)
ORDER BY 
    t.production_year DESC, 
    t.total_cast DESC
LIMIT 50;
