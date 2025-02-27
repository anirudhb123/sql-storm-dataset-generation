WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
),
RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
HighlyRatedMovies AS (
    SELECT 
        m.movie_id, 
        AVG(mi.info::numeric) AS average_rating
    FROM 
        movie_info mi
    JOIN 
        title t ON mi.movie_id = t.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.movie_id
    HAVING 
        AVG(mi.info::numeric) >= 8.0
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CombinedStats AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        hk.keywords,
        COALESCE(hm.average_rating, 0) AS average_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        HighlyRatedMovies hm ON rm.movie_rank = hm.movie_id
    LEFT JOIN 
        MovieKeywords hk ON rm.movie_id = hk.movie_id
)
SELECT 
    c.actor_name,
    c.movie_title,
    c.production_year,
    c.keywords,
    c.average_rating
FROM 
    CombinedStats c
WHERE 
    c.average_rating > 0 
    AND (c.keywords IS NULL OR c.keywords LIKE '%action%')
ORDER BY 
    c.average_rating DESC, 
    c.production_year DESC;

This complex SQL query combines multiple techniques, including:

- **Common Table Expressions (CTEs)**: Used to create reusable subqueries (ActorHierarchy, RankedMovies, HighlyRatedMovies, MovieKeywords, CombinedStats).
- **Window functions**: Used for ranking actors and movies (ROW_NUMBER()).
- **Aggregate functions and string aggregation**: To calculate average ratings and concatenate keywords.
- **Outer joins**: To include movies that may not have ratings and keywords.
- **Complicated predicates**: Filtering for movies with ratings and specific keywords.
- **NULL logic**: To ensure results are shown even if keywords are missing.
