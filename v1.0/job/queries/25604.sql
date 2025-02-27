WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.total_cast,
        ci.actor_names
    FROM 
        RankedMovies rm
    JOIN 
        CastInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.info, 'No Info') AS movie_info
FROM 
    MovieDetails md
LEFT JOIN 
    (SELECT movie_id, STRING_AGG(keyword.keyword, ', ') AS keywords
     FROM movie_keyword mk
     JOIN keyword keyword ON mk.keyword_id = keyword.id
     GROUP BY mk.movie_id) mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, STRING_AGG(info, '; ') AS info
     FROM movie_info
     GROUP BY movie_id) mi ON md.movie_id = mi.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
