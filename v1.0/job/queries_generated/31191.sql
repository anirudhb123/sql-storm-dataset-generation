WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        coalesce(an.name, 'Unknown') AS actor_name,
        1 AS hierarchy_level
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.movie_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        coalesce(an.name, 'Unknown') AS actor_name,
        h.hierarchy_level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy h ON ci.movie_id = h.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.id <> h.cast_id
),
MoviesWithInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000 AND 
        (ak.name IS NOT NULL OR ci.note IS NOT NULL)
    GROUP BY 
        t.title, 
        t.production_year
),
RankedMovies AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.actors,
        m.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.keyword_count DESC) AS rank
    FROM 
        MoviesWithInfo m
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actors,
    rm.keyword_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC;

