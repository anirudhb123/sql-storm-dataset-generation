WITH RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        T.id AS movie_id,
        AK.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY T.id ORDER BY CA.nr_order) AS actor_rank
    FROM 
        aka_title T
    JOIN 
        cast_info CA ON T.id = CA.movie_id
    JOIN 
        aka_name AK ON CA.person_id = AK.person_id
    WHERE 
        T.production_year >= 2000 
        AND AK.name IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MoviesWithKeywords AS (
    SELECT 
        M.title,
        M.production_year,
        array_agg(K.keyword) AS keywords
    FROM 
        aka_title M
    JOIN 
        movie_keyword MK ON M.id = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        M.production_year >= 2000
    GROUP BY 
        M.title, M.production_year
),
FinalResults AS (
    SELECT 
        R.actor_name,
        R.movie_count,
        M.title,
        M.production_year,
        M.keywords
    FROM 
        TopActors R
    LEFT JOIN 
        MoviesWithKeywords M ON R.movie_count > 0
)

SELECT 
    actor_name,
    movie_count,
    title,
    production_year,
    keywords
FROM 
    FinalResults
ORDER BY 
    movie_count DESC, production_year DESC;

This query performs multiple processing steps:

1. **RankedMovies CTE**: It constructs a ranked list of movies produced from the year 2000 onwards and their top 3 actors.
2. **TopActors CTE**: It aggregates the ranked movies to get the top 10 actors based on the number of movies they starred in that are ranked.
3. **MoviesWithKeywords CTE**: It gathers movies produced from 2000 onwards along with their associated keywords.
4. **FinalResults CTE**: It combines the actors with their movie counts and details of movies along with keywords.
5. **Final SELECT**: Displays the actor name, movie count, movie title, production year, and a list of keywords associated with those movies, ordered by the count of movies and then by the production year.

This structure tests string processing performance through substantial manipulations of several text fields, aggregations, and joins.
