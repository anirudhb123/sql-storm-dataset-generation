WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
MovieDetails AS (
    SELECT 
        at.title, 
        at.production_year, 
        ak.name AS actor_name, 
        ak.surname_pcode,
        COALESCE(mk.keyword, 'Unknown') AS keyword
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        ak.name IS NOT NULL
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    md.actor_name,
    md.surname_pcode,
    md.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieDetails md ON rm.title = md.title AND rm.production_year = md.production_year 
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;

WITH MovieInfoV AS (
    SELECT 
        mi.movie_id,
        string_agg(mi.info, '; ') AS combined_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    at.title,
    mi.combined_info
FROM 
    aka_title at
LEFT JOIN 
    MovieInfoV mi ON at.movie_id = mi.movie_id
WHERE 
    at.production_year BETWEEN 2000 AND 2020
AND 
    (mi.combined_info IS NOT NULL OR EXISTS (SELECT 1 FROM movie_info_idx WHERE movie_id = at.movie_id));
