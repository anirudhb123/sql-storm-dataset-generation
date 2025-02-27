WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, a.name AS actor_name, 1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id = (SELECT id FROM aka_title WHERE title LIKE '%Avengers%' LIMIT 1)

    UNION ALL

    SELECT c.person_id, a.name AS actor_name, ah.level + 1
    FROM cast_info c 
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.person_id -- hypothetical recursive relationship
)
, MovieWithKeywords AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM aka_title at
    JOIN movie_keyword mk ON at.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY at.id, at.title
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name END) AS distributor_name
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
RankedMovies AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.keywords,
        cs.company_count,
        cs.distributor_name,
        ROW_NUMBER() OVER (ORDER BY cs.company_count DESC) AS movie_rank
    FROM MovieWithKeywords mw
    LEFT JOIN CompanyStats cs ON mw.movie_id = cs.movie_id
)
SELECT 
    rm.title,
    rm.keywords,
    COALESCE(rm.company_count, 0) AS total_companies,
    rm.distributor_name,
    ah.actor_name,
    ah.level
FROM RankedMovies rm
LEFT JOIN ActorHierarchy ah ON rm.movie_id = ah.person_id
WHERE ah.level <= 2 OR ah.level IS NULL
ORDER BY rm.movie_rank, ah.level, rm.title;
