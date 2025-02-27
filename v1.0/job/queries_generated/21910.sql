WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
HighlyRatedMovies AS (
    SELECT 
        m.movie_id,
        m.info AS rating
    FROM 
        movie_info m
    INNER JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info = 'rating' AND
        m.info::float >= 8.0
),
TitleWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mt
    INNER JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(hm.rating, 'N/A') AS rating,
    COALESCE(tw.keywords, 'None') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCount ac ON r.movie_id = ac.movie_id
LEFT JOIN 
    HighlyRatedMovies hm ON r.movie_id = hm.movie_id
LEFT JOIN 
    TitleWithKeywords tw ON r.movie_id = tw.movie_id
WHERE 
    r.rank_per_year <= 5
ORDER BY 
    r.production_year DESC, 
    actor_count DESC,
    rating DESC NULLS LAST;

### Query Explanation:
1. **CTEs (Common Table Expressions)**: The query defines four CTEs:
    - **RankedMovies** assigns a rank to movies based on their production year.
    - **ActorCount** counts the distinct actors for each movie.
    - **HighlyRatedMovies** identifies movies with a rating of 8.0 or higher.
    - **TitleWithKeywords** aggregates keywords associated with each movie into a comma-separated string.

2. **Joins**: The main query LEFT JOINs these CTEs to compile a comprehensive list containing the title, production year, actor count, rating (if applicable), and associated keywords for the movies that fall within the top 5 ranks per year.

3. **COALESCE**: Handles NULL values by providing default values ('N/A' for ratings, 'None' for keywords) when counting actors or when no data is found.

4. **Complexity & Unusual Logic**: 
    - Incorporates correlated counts from multiple sources (actors, keywords).
    - Uses advanced SQL constructs like `ROW_NUMBER()`, `STRING_AGG()`, and ordering with `NULLS LAST`.
    - Filters based on properties such as production year rank and rating thresholds, demonstrating a nuanced approach to data retrieval. 

5. **Sorting**: Orders the results primarily by production year, then by actor count, and finally by rating, which highlights movies that are both recent and well-acted.
