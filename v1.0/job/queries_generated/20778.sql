WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS rank_within_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),

ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),

PopularMovies AS (
    SELECT 
        R.*,
        COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count
    FROM 
        RankedMovies R
    LEFT JOIN 
        movie_info mi ON R.movie_id = mi.movie_id
    GROUP BY 
        R.movie_id, R.title, R.production_year
),

HighRankedMovies AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        pm.info_count,
        RANK() OVER (ORDER BY pm.info_count DESC, pm.production_year DESC) AS movie_rank
    FROM 
        PopularMovies pm
    WHERE 
        pm.info_count > 0 
)

SELECT 
    ak.name AS actor_name,
    ak.surname_pcode,
    hm.title AS movie_title,
    hm.production_year,
    hm.info_count
FROM 
    aka_name ak 
JOIN 
    ActorMovieCounts amc ON ak.person_id = amc.person_id
LEFT JOIN 
    complete_cast cc ON amc.person_id = cc.subject_id
LEFT JOIN 
    HighRankedMovies hm ON cc.movie_id = hm.movie_id
WHERE 
    (hm.info_count IS NOT NULL OR hm.production_year IS NOT NULL)
    AND (hm.movie_rank <= 10 OR hm.title LIKE '%in%')
ORDER BY 
    ak.name, hm.production_year DESC;

-- The query constructs elaborate relationships:
-- 1. CTEs to rank movies by year and count actor appearances in movies.
-- 2. A final query joining actor names to high-ranked movies filtered by various criteria.
-- 3. It incorporates complex conditions, including NULL handling and string pattern matching.
