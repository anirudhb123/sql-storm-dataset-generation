WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        ci.nr_order,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, ci.movie_id, ci.nr_order
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.actor_name,
        pk.keyword,
        pk.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY pk.keyword_count DESC) AS keyword_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorInfo ai ON rm.movie_id = ai.movie_id
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(md.keyword, 'No Keywords') AS keywords,
    md.keyword_count,
    md.keyword_rank
FROM 
    MovieDetails md
WHERE 
    (md.keyword_count > 1 OR md.keyword IS NULL)
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC NULLS LAST;
