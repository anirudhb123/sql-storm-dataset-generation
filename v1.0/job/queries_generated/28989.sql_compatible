
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_actor_names
    FROM 
        RankedMovies rm
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.all_actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.movie_id
ORDER BY 
    md.actor_count DESC, md.production_year DESC;
