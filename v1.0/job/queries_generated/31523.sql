WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS movie_count,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(*) > 5  -- Only include actors with more than 5 movies
    UNION ALL
    SELECT 
        ch.person_id,
        COUNT(*) AS movie_count,
        level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ch ON ah.person_id = ch.person_id
    GROUP BY 
        ch.person_id
),
RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(mc.company_id) AS company_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    ah.movie_count,
    rm.title AS movie_title,
    rm.production_year,
    rm.company_count,
    mk.keyword AS associated_keyword
FROM 
    aka_name a
LEFT JOIN 
    ActorHierarchy ah ON a.person_id = ah.person_id
LEFT JOIN 
    RankedMovies rm ON ah.movie_count = rm.rank
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 10  -- Get top 10 movies based on company presence
    AND ah.level = 1  -- Only select top-level actors
    AND mk.keyword_rank IS NOT NULL  -- Ensure there's at least one keyword associated
ORDER BY 
    a.name, rm.production_year DESC;
