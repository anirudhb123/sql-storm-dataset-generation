WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title mt 
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),

KeywordCountCTE AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        RecursiveMovieCTE rm
    LEFT JOIN 
        KeywordCountCTE kc ON rm.movie_id = kc.movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    md.keyword_count,
    kt.kind AS movie_kind
FROM 
    MovieDetails md
JOIN 
    kind_type kt ON md.kind_id = kt.id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.cast_count DESC, 
    md.keyword_count DESC
LIMIT 10;
