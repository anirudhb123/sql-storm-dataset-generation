
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
HighActorMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
),
MovieKeywords AS (
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
    ham.title,
    ham.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT 
        COUNT(DISTINCT ci.person_id)
     FROM 
        cast_info ci
     JOIN 
        aka_title at ON ci.movie_id = at.id
     WHERE 
        at.production_year = ham.production_year
    ) AS total_actors_in_year
FROM 
    HighActorMovies ham
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = ham.title LIMIT 1)
ORDER BY 
    ham.production_year DESC, ham.title ASC;
