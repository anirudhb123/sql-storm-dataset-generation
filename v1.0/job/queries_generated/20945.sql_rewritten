WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_per_year
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
        AND mt.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        c.movie_id,
        RANK() OVER (PARTITION BY ak.name ORDER BY COUNT(c.note) DESC) AS movie_count_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, ak.person_id, c.movie_id
),
NULLCheck AS (
    SELECT 
        movie_id,
        COUNT(*) AS null_attributes_count
    FROM 
        complete_cast 
    WHERE 
        subject_id IS NULL 
        OR status_id IS NULL
    GROUP BY 
        movie_id
),
TopKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.movie_count_rank,
    COALESCE(nc.null_attributes_count, 0) AS null_attributes,
    tk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id AND ai.movie_count_rank = 1 
LEFT JOIN 
    NULLCheck nc ON rm.movie_id = nc.movie_id
LEFT JOIN 
    TopKeywords tk ON rm.movie_id = tk.movie_id
WHERE 
    rm.rank_per_year <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.title, 
    ai.movie_count_rank 
LIMIT 100;