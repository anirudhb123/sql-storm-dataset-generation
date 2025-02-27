WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_info_length
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title
),
ActorsSummary AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        COUNT(actor_id) AS total_actors
    FROM 
        ActorsInMovies
    GROUP BY 
        movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.avg_info_length,
    asu.actors,
    asu.total_actors,
    rt.title_rank
FROM 
    MovieDetails md
LEFT JOIN 
    ActorsSummary asu ON md.movie_id = asu.movie_id
JOIN 
    RankedTitles rt ON md.title = rt.title AND md.production_year = rt.production_year
WHERE 
    md.keyword_count > 5
ORDER BY 
    md.production_year DESC, rt.title_rank ASC;
