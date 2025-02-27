WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        cast_info.nr_order AS cast_order
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1  -- Start with main cast roles
    UNION ALL
    SELECT 
        c.person_id,
        c.movie_id,
        cast_info.nr_order
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id AND c.nr_order = ah.cast_order + 1
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.person_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS actor_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year, a.person_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ci.kind, ', ') AS company_types
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mk.movie_id = mc.movie_id
    JOIN 
        company_type ci ON mc.company_type_id = ci.id
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    ah.person_id,
    m.keywords,
    m.company_types,
    COALESCE(a.actor_rank, 0) AS actor_rank
FROM 
    title t
LEFT JOIN 
    ActorHierarchy ah ON t.id = ah.movie_id
LEFT JOIN 
    MovieInfo m ON t.id = m.movie_id
LEFT JOIN 
    RankedMovies a ON t.production_year = a.production_year AND ah.person_id = a.person_id
WHERE 
    t.production_year IS NOT NULL 
    AND (m.keywords IS NOT NULL OR m.company_types IS NOT NULL)
ORDER BY 
    t.production_year DESC, actor_rank;
