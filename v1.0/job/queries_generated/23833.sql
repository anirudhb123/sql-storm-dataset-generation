WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DistinctActors AS (
    SELECT DISTINCT 
        c.person_id,
        n.name,
        r.role
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        n.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)
SELECT 
    rm.title,
    rm.production_year,
    COUNT(DISTINCT da.person_id) AS total_actors,
    STRING_AGG(DISTINCT dk.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT da.person_id) > 10 THEN 'Ensemble Cast'
        WHEN COUNT(DISTINCT da.person_id) BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    MAX(CASE WHEN rm.year_rank = 1 THEN 'Yes' ELSE 'No' END) AS is_latest_movie,
    COALESCE(SUM(NULLIF(rm.production_year - a.production_year, 0)), 0) AS year_difference,
    MAX(CASE WHEN da.name IS NULL THEN 'Unknown Actor' ELSE da.name END) AS leading_actor_name
FROM 
    RankedMovies rm
LEFT JOIN 
    DistinctActors da ON da.person_id IN (
        SELECT DISTINCT c.person_id 
        FROM cast_info c 
        WHERE c.movie_id = rm.movie_id
    )
LEFT JOIN 
    MovieKeywords dk ON dk.movie_id = rm.movie_id 
GROUP BY 
    rm.title, rm.production_year
HAVING 
    COUNT(DISTINCT da.person_id) >= 3 AND 
    rm.production_year < (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC;
