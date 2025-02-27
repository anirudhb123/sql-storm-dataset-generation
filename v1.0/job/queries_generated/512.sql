WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
), ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        mk.movie_id,
        CASE 
            WHEN pi.info IS NOT NULL THEN pi.info
            ELSE 'No info available' 
        END AS biography
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    mk.keywords,
    ai.actor_name,
    ai.biography
FROM 
    RankedMovies rm
JOIN 
    MovieKeywords mk ON mk.movie_id = rm.title
JOIN 
    ActorInfo ai ON ai.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
