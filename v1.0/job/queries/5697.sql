
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS aliases,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.aliases,
        COALESCE(mk.keywords, ARRAY[]::TEXT[]) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        (SELECT 
             mk.movie_id, 
             ARRAY_AGG(kw.keyword) AS keywords
         FROM 
             movie_keyword mk
         JOIN 
             keyword kw ON mk.keyword_id = kw.id
         GROUP BY 
             mk.movie_id) mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.aliases,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.total_cast > 5 AND
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC
LIMIT 10;
