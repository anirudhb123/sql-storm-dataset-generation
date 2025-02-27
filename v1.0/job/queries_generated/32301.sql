WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link l ON m.id = l.linked_movie_id
    JOIN 
        MovieHierarchy h ON l.movie_id = h.movie_id
),
CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(cc.actor_count, 0) AS actor_count,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(cc.actor_count, 0) DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastCount cc ON mh.movie_id = cc.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    COUNT(DISTINCT mi.info) AS info_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    ROUND(AVG(levenshtein(tm.movie_title, cn.name)), 2) AS avg_name_similarity
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_title, tm.production_year, tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
