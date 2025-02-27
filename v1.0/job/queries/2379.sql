WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN c.nr_order IS NULL THEN 0 ELSE c.nr_order END) AS avg_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
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
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        k.keywords,
        COALESCE(a.movie_count, 0) AS total_actors,
        COALESCE(a.avg_order, 0) AS avg_actor_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords k ON rm.movie_id = k.movie_id
    LEFT JOIN 
        ActorStats a ON rm.movie_id = a.person_id
)
SELECT 
    fm.*,
    CASE 
        WHEN fm.total_actors > 10 THEN 'Blockbuster'
        WHEN fm.total_actors >= 5 AND fm.total_actors <= 10 THEN 'Moderately Successful'
        ELSE 'Indie Flick'
    END AS movie_success_category,
    CASE 
        WHEN fm.avg_actor_order IS NULL THEN 'No Order Info'
        ELSE 'Order Recorded'
    END AS order_info
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year > 2000
ORDER BY 
    fm.production_year DESC, fm.title ASC
LIMIT 100;
