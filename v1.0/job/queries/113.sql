WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        c.nr_order,
        r.role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
ActorCounts AS (
    SELECT 
        ad.movie_id,
        COUNT(ad.actor_id) AS actor_count
    FROM 
        ActorDetails ad
    GROUP BY 
        ad.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(m.info, '; ') AS movie_info
    FROM 
        movie_info m
    JOIN 
        aka_title t ON m.movie_id = t.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id, 
    r.title,
    r.production_year,
    ac.actor_count,
    mi.movie_info,
    CASE 
        WHEN ac.actor_count >= 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCounts ac ON r.movie_id = ac.movie_id
LEFT JOIN 
    MovieInfo mi ON r.movie_id = mi.movie_id
WHERE 
    r.rank_within_year <= 10
ORDER BY 
    r.production_year DESC, 
    ac.actor_count DESC NULLS LAST;
