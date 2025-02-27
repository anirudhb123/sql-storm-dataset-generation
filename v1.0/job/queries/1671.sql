WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        ac.actor_count,
        COALESCE(mi.info, 'No information available') AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        ActorCount ac ON tm.movie_id = ac.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.movie_info,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_ratio
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    md.actor_count > 0
GROUP BY 
    md.title, md.production_year, md.actor_count, md.movie_info
ORDER BY 
    md.production_year DESC, md.title;
