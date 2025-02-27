WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year) AS year_rank,
        ROW_NUMBER() OVER (PARTITION BY a.production_year, k.keyword ORDER BY a.title) AS keyword_rank,
        a.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
ActorInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(CASE WHEN ak.name ILIKE '%john%' THEN ak.name END) AS notable_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithNulls AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.actor_count,
        ai.actors,
        ai.notable_actor,
        COALESCE(ai.actor_count, 0) AS safe_actor_count,
        COALESCE(ai.actors, 'No Actors') AS safe_actors,
        CASE 
            WHEN ai.actor_count IS NULL THEN 'Unknown'
            WHEN ai.actor_count < 3 THEN 'Few Actors'
            ELSE 'Many Actors'
        END AS actor_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorInfo ai ON rm.movie_id = ai.movie_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.actors,
    mw.notable_actor,
    mw.safe_actor_count,
    mw.safe_actors,
    mw.actor_category,
    CASE 
        WHEN mw.production_year < 2000 THEN 'Classic'
        WHEN mw.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS period_category,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mw.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')) AS summary_count
FROM 
    MoviesWithNulls mw
WHERE 
    mw.title IS NOT NULL
ORDER BY 
    mw.production_year DESC,
    mw.actor_count DESC NULLS LAST,
    mw.title;
