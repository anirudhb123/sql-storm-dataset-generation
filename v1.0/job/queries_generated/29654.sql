WITH RankedMovies AS (
    SELECT 
        mt.title,
        a.name AS actor_name,
        c.nr_order,
        a.id AS actor_id,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.id ORDER BY c.nr_order) AS rank_order
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        mt.production_year >= 2000
),
FilteredActors AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank_order = 1
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalReport AS (
    SELECT 
        rm.title,
        rm.production_year,
        fa.actor_name,
        fa.movie_count,
        mk.keywords
    FROM 
        RankedMovies rm
    JOIN 
        FilteredActors fa ON rm.actor_name = fa.actor_name
    LEFT JOIN 
        MovieKeywords mk ON rm.id = mk.movie_id
    WHERE 
        rm.rank_order = 1
)
SELECT 
    title,
    production_year,
    actor_name,
    movie_count,
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    FinalReport
ORDER BY 
    production_year DESC, movie_count DESC;
