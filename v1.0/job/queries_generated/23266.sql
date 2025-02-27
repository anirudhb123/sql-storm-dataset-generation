WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS rn
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%feature%')
),
ActorMovies AS (
    SELECT 
        a.person_id,
        ARRAY_AGG(DISTINCT m.title ORDER BY m.production_year) AS movies
    FROM 
        (SELECT DISTINCT ci.person_id, ci.movie_id
         FROM cast_info ci 
         JOIN movie_companies mc ON ci.movie_id = mc.movie_id
         WHERE mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
        ) a
    JOIN rankedMovies m ON a.movie_id = m.id
    GROUP BY a.person_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
MoviesWithNoCast AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        aka_title m
    LEFT JOIN CompanyCounts cc ON m.id = cc.movie_id
    WHERE 
        m.id NOT IN (SELECT DISTINCT movie_id FROM cast_info)
)
SELECT 
    m.title,
    m.production_year,
    ac.movies AS actor_movies,
    m.company_count,
    (SELECT COUNT(*) FROM info_type it WHERE it.info ILIKE '%biopic%') AS biopic_count
FROM 
    MoviesWithNoCast m
LEFT JOIN ActorMovies ac ON m.id IN (SELECT unnest(ac.movies) FROM ac)
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL)
ORDER BY 
    m.company_count DESC NULLS LAST;
