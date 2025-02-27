WITH MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(SUM(CASE WHEN mc.company_type_id = 1 THEN 1 ELSE 0 END), 0) AS production_count,
        COALESCE(SUM(CASE WHEN mc.company_type_id = 2 THEN 1 ELSE 0 END), 0) AS distribution_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS featured_roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
),
RankedMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.keywords,
        RANK() OVER (PARTITION BY mi.production_year ORDER BY mi.production_count DESC, mi.distribution_count DESC) AS rank
    FROM 
        MovieInfo mi
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    ai.name AS lead_actor,
    ai.movie_count,
    ai.featured_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id AND ci.nr_order = 1
LEFT JOIN 
    aka_name ai ON ci.person_id = ai.person_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.rank;
