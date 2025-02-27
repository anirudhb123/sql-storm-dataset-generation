
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rnk,
        at.movie_id   -- Adding the movie_id to the select list for joining later
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year, at.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT 
         COUNT(DISTINCT ai.person_id) 
     FROM 
         aka_name ai 
     WHERE 
         ai.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
     ) AS distinct_name_count,
    CASE 
        WHEN rm.actor_count > 5 THEN 'Large Cast'
        WHEN rm.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.actor_count > 0) 
    OR (rm.rnk <= 10)
ORDER BY 
    rm.actor_count DESC, 
    rm.production_year DESC;
