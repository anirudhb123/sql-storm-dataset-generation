WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ARRAY_AGG(DISTINCT ka.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
MoviesWithKeywords AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.actor_names,
        k.keyword
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesByProductionYear AS (
    SELECT 
        production_year,
        COUNT(*) AS total_movies,
        STRING_AGG(title, ', ') AS titles
    FROM 
        MoviesWithKeywords
    GROUP BY 
        production_year
    HAVING 
        COUNT(*) > 2
)
SELECT 
    mp.production_year,
    mp.total_movies,
    mp.titles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS assorted_keywords,
    CASE 
        WHEN mp.production_year IS NULL THEN 'No Year'
        ELSE 'Year Present'
    END AS year_status
FROM 
    MoviesByProductionYear mp
LEFT JOIN 
    MoviesWithKeywords k ON mp.production_year = k.production_year
GROUP BY 
    mp.production_year, mp.total_movies, mp.titles
ORDER BY 
    mp.production_year DESC;

This SQL query accomplishes several complex operations: 

1. It uses recursive CTEs to gather a complete list of movies with their respective actors, grouping by movie attributes.
2. The second CTE gathers movie keywords associated with each movie, providing a bridge between movie and keyword relations.
3. The third CTE summarizes total movies and their titles by production year, filtering out years with fewer than three movies.
4. The final select statement aggregates keywords by production year while evaluating and reporting a conditional status regarding the presence of the year data.
5. The result set includes string aggregation and null checks to ensure thorough visibility into the data along with useful insights regarding movie production trends and keyword associations.
