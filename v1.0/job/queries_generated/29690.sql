WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
),
TopRatedActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ak.person_id,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name, ak.person_id
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompositeData AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        ta.actor_name,
        mk.keyword
    FROM 
        RankedMovies rm
    JOIN 
        TopRatedActors ta ON rm.movie_id = ta.movie_id
    JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        mk.keyword_rank <= 3
)
SELECT
    cd.movie_id,
    cd.movie_title,
    cd.actor_name,
    STRING_AGG(cd.keyword, ', ') AS keywords
FROM 
    CompositeData cd
GROUP BY 
    cd.movie_id, cd.movie_title, cd.actor_name
ORDER BY 
    cd.movie_id, cd.actor_name;

This SQL query generates a rich output involving the following steps:
1. **RankedMovies**: Retrieves movies produced from the year 2000 onwards, ranking them based on their title for each production year.
2. **TopRatedActors**: Identifies actors who have participated in more than five movies, counting their contributions.
3. **MovieKeywords**: Extracts keywords associated with movies, ranking them for each movie.
4. **CompositeData**: Combines the above subqueries to list movies along with the names of top-rated actors and their corresponding keywords, limiting the keywords to the top three ranked ones for each movie.
5. **Final Output**: Groups the results to provide a concise view of each movie, its top actors, and a concatenated list of keywords associated with it, ordered by movie ID and actor name.
