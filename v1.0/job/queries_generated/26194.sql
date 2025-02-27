WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title AT
    JOIN 
        title t ON AT.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    AND 
        AT.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieInfoWithCount AS (
    SELECT 
        t.id AS title_id,
        COUNT(mi.info) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_list
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
),
ActorMovieCount AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
)

SELECT 
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.actor_rank,
    miwc.info_count,
    miwc.info_list,
    amc.movie_count
FROM 
    RankedTitles rt
JOIN 
    MovieInfoWithCount miwc ON rt.title_id = miwc.title_id
JOIN 
    ActorMovieCount amc ON rt.actor_name = amc.actor_name
ORDER BY 
    rt.production_year DESC, amc.movie_count DESC;
