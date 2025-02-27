WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        ci.movie_id,
        c.role_id,
        r.role
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
DistinctGenres AS (
    SELECT 
        mt.id AS movie_id,
        string_agg(DISTINCT kt.kind, ', ') AS genres
    FROM 
        aka_title mt
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
    GROUP BY 
        mt.id
)
SELECT 
    COUNT(DISTINCT ai.name) AS total_actors,
    dm.title,
    COALESCE(dm.production_year, 'Unknown Year') AS production_year,
    COALESCE(dg.genres, 'No genres') AS genres,
    COALESCE(array_agg(DISTINCT mk.keyword ORDER BY mk.keyword), '{}') AS keywords,
    SUM(CASE WHEN ai.role IS NOT NULL THEN 1 ELSE 0 END) AS actor_roles_count,
    string_agg(DISTINCT ai.role ORDER BY ai.role) AS distinct_roles,
    MAX(CASE WHEN mk.keyword_rank = 1 THEN mk.keyword END) AS top_keyword
FROM 
    RankedMovies dm
LEFT JOIN 
    ActorInfo ai ON dm.movie_id = ai.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = dm.movie_id
LEFT JOIN 
    DistinctGenres dg ON dm.movie_id = dg.movie_id
WHERE 
    dm.year_rank <= 5 -- Get only the top 5 movies per year
GROUP BY 
    dm.movie_id, dm.title, dm.production_year, dg.genres
ORDER BY 
    total_actors DESC, dm.production_year DESC NULLS LAST;
