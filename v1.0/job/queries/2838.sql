
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
MovieDetails AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COALESCE(cr.num_actors, 0) AS total_actors,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title
    LEFT JOIN 
        CastRoles cr ON title.id = cr.movie_id
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    GROUP BY 
        title.id, title.title, title.production_year, cr.num_actors
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_actors,
        md.keyword_count,
        (md.total_actors * 1.0 / NULLIF(md.keyword_count, 0)) AS actor_keyword_ratio
    FROM 
        MovieDetails md
    WHERE 
        md.production_year IS NOT NULL
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.total_actors,
    fb.keyword_count,
    fb.actor_keyword_ratio
FROM 
    FinalBenchmark fb
WHERE 
    fb.actor_keyword_ratio > 2 OR fb.total_actors > 10
ORDER BY 
    fb.production_year DESC, 
    fb.actor_keyword_ratio DESC;
