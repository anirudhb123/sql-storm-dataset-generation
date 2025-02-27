WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
    UNION ALL
    SELECT 
        mt.linked_movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.depth + 1
    FROM 
        movie_link mt
    JOIN 
        aka_title t ON mt.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mt.movie_id = mh.movie_id
),
ActorMovieInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.role_id) AS role_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        c.movie_id, a.name
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ai.actor_name,
        ai.role_count,
        ai.keywords,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY ai.role_count DESC) AS actor_role_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorMovieInfo ai ON mh.movie_id = ai.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    COALESCE(rm.actor_name, 'No Actors') AS actor_name,
    COALESCE(rm.role_count, 0) AS role_count,
    rm.keywords,
    CASE 
        WHEN rm.actor_role_rank <= 3 THEN 'Top Ranked Actor'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies rm
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    rm.actor_role_rank;
