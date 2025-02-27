WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        COALESCE(STRING_AGG(DISTINCT kw.keyword, ', '), 'No keywords') AS keywords,
        ROW_NUMBER() OVER(PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
        JOIN cast_info ci ON at.id = ci.movie_id
        JOIN aka_name ak ON ci.person_id = ak.person_id
        LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
        LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year, ak.name
),
MovieStats AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name) AS all_actors,
        COUNT(DISTINCT actor_name) AS actor_count,
        keywords
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year, keywords
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.all_actors,
    ms.actor_count,
    ms.keywords,
    CASE 
        WHEN ms.actor_count > 5 THEN 'Ensemble Cast' 
        WHEN ms.actor_count BETWEEN 3 AND 5 THEN 'Moderate Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    MovieStats ms
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
