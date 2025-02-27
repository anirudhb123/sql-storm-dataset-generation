WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
ActorStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(CASE WHEN ti.production_year > 2000 THEN 1 ELSE 0 END) AS post_2000_rate
    FROM 
        cast_info c
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN 
        title ti ON cc.subject_id = ti.id
    GROUP BY 
        c.person_id
)

SELECT 
    na.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    rm.keyword,
    as.total_movies,
    as.post_2000_rate
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    ActorStats as ON ci.person_id = as.person_id
WHERE 
    rm.title_rank <= 10
    AND as.total_movies > 5
ORDER BY 
    rm.production_year DESC,
    rm.title ASC;

WITH RecursiveAssociations AS (
    SELECT 
        m.movie_id,
        mc.company_id,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY mc.company_id) AS rn
    FROM 
        movie_companies mc
    JOIN 
        title m ON mc.movie_id = m.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
), 
NullCheck AS (
    SELECT 
        ra.movie_id,
        COUNT(*) FILTER (WHERE ra.company_id IS NULL) AS null_count
    FROM 
        RecursiveAssociations ra
    GROUP BY 
        ra.movie_id
)

SELECT 
    t.title,
    COALESCE(nc.null_count, 0) AS missing_distributors
FROM 
    title t
LEFT JOIN 
    NullCheck nc ON t.id = nc.movie_id
WHERE 
    t.production_year >= 2010
ORDER BY 
    missing_distributors DESC
LIMIT 20;
