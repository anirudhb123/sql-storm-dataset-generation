WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        1 AS level
    FROM 
        cast_info ai
    JOIN 
        aka_name ak ON ai.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL

    UNION ALL

    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ai
    JOIN 
        aka_name ak ON ai.person_id = ak.person_id
    JOIN 
        ActorHierarchy ah ON ai.movie_id IN (
            SELECT movie_id 
            FROM cast_info c2 
            WHERE c2.person_id = ah.person_id
        )
    WHERE 
        ak.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        mi.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS ranked_position
    FROM 
        MovieInfo mi
),
NullFeatureCheck AS (
    SELECT 
        title,
        production_year,
        COALESCE(company_names, 'No companies') AS applicable_companies,
        CASE 
            WHEN ranked_position IS NULL THEN 'Rank not available'
            ELSE ranked_position::text 
        END AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    nh.actor_name,
    nfc.title,
    nfc.production_year,
    nfc.applicable_companies,
    nfc.movie_rank
FROM 
    ActorHierarchy nh
FULL OUTER JOIN 
    NullFeatureCheck nfc ON nh.actor_name LIKE '%' || nfc.title || '%' 
WHERE  
    nfc.production_year BETWEEN 1980 AND 2023
    AND (
        nfc.movie_rank IS NOT NULL 
        OR nh.actor_name IS NULL
    )
ORDER BY 
    nfc.production_year DESC, 
    nh.actor_name ASC;

This query generates a recursive CTE, `ActorHierarchy`, to analyze actors and their roles across movies, builds a detailed `MovieInfo` CTE to aggregate companies and keywords associated with each title, ranks movies based on keyword diversity, checks for NULL conditions in another CTE, and finally combines this data with a full outer join. It contains complex predicates for filtering actors against movie titles and handles NULL logic in a nuanced manner, ensuring a comprehensive view of the data.
