
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count,
        STRING_AGG(a.name, ', ' ORDER BY a.name) AS actor_names
    FROM 
        aka_title mt
    JOIN 
        complete_cast c ON mt.id = c.movie_id
    JOIN 
        cast_info cc ON c.subject_id = cc.person_id
    JOIN 
        aka_name a ON cc.person_id = a.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.actor_names,
        k.keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        KeywordStats k ON r.movie_id = k.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    COALESCE(md.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.cast_count DESC, md.production_year ASC
LIMIT 10;
