WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY mt.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.production_year BETWEEN 2000 AND 2023
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IN ('actor', 'actress')
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rc.actor_count,
        COALESCE(NULLIF(rm.kind_id, 0), 99) AS adjusted_kind_id, -- Assuming 99 refers to an 'unknown' kind
        CASE 
            WHEN rm.keyword_count = 0 THEN 'No keywords'
            ELSE 'Has keywords'
        END AS keyword_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts rc ON rm.id = rc.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.adjusted_kind_id,
    md.keyword_status
FROM 
    MovieDetails md
WHERE 
    md.year_rank <= 5
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC, 
    md.movie_title ASC;

-- Counting Keywords used in the last 3 Years
WITH RecentKeyWords AS (
    SELECT 
        mk.keyword, 
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title at ON mk.movie_id = at.id
    WHERE 
        at.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 3
    GROUP BY 
        mk.keyword
    HAVING 
        COUNT(DISTINCT mk.movie_id) > 1
)
SELECT * FROM RecentKeyWords;

-- Integration of Outer Join Semantics
SELECT 
    a.name,
    COALESCE(ca.actor_count, 0) AS actor_count
FROM 
    name a
LEFT JOIN 
    (SELECT 
        ci.person_id, 
        COUNT(DISTINCT ci.movie_id) AS actor_count
     FROM 
        cast_info ci
     GROUP BY 
        ci.person_id) ca 
ON 
    a.id = ca.person_id
WHERE 
    a.gender = 'F'
ORDER BY 
    actor_count DESC NULLS LAST;
