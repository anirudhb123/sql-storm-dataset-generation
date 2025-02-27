WITH RECURSIVE FeaturedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopFeaturedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year
    FROM 
        FeaturedMovies fm
    WHERE 
        fm.rn <= 5
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COALESCE(ak.name, 'Unknown Actor') AS actor_name,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.title, mt.production_year
),
FinalReport AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(ar.actor_name, 'No Actors') AS actor_name,
        ar.role,
        mi.actors,
        mi.info_count
    FROM 
        TopFeaturedMovies tm
    LEFT JOIN 
        ActorRoles ar ON tm.movie_id = ar.movie_id
    LEFT JOIN 
        MovieInfo mi ON tm.title = mi.title AND tm.production_year = mi.production_year
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.role,
    f.actors,
    f.info_count
FROM 
    FinalReport f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, f.title;
