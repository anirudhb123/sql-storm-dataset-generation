WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        a.name AS director_name,
        COUNT(DISTINCT ci.person_id) AS number_of_directors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        ci.movie_id, a.name
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    di.director_name,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    di.number_of_directors,
    CASE 
        WHEN di.number_of_directors > 1 THEN 'Multiple Directors'
        ELSE 'Single Director'
    END AS director_status
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorInfo di ON rm.movie_id = di.movie_id
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
