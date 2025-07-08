
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        eit.id AS movie_id,
        eit.title,
        eit.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title eit
    JOIN 
        MovieHierarchy mh ON eit.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),
ActorMovieCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.level,
    ac.actor_count,
    cc.company_count,
    COALESCE(ac.actor_count, 0) AS actor_count_coalesced,
    COALESCE(cc.company_count, 0) AS company_count_coalesced
FROM 
    TopMovies tm
LEFT JOIN 
    ActorMovieCount ac ON tm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyContribution cc ON tm.movie_id = cc.movie_id
WHERE 
    tm.rank <= 3 AND
    (tm.production_year >= 2000 OR ac.actor_count IS NOT NULL)
ORDER BY 
    tm.level,
    tm.production_year DESC;
