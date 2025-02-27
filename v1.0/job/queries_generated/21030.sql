WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        ak.person_id,
        COUNT(DISTINCT t.id) AS appearances,
        RANK() OVER (ORDER BY COUNT(DISTINCT t.id) DESC) AS appearance_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        ak.id, ak.name, ak.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        SUM(mk.keyword IS NOT NULL) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.all_keywords,
    ra.actor_count,
    pa.name AS popular_actor,
    pa.appearances
FROM 
    MovieDetails md
LEFT JOIN 
    RankedMovies ra ON md.production_year = ra.production_year AND ra.rank = 1
LEFT JOIN 
    PopularActors pa ON pa.appearance_rank = 1
WHERE 
    md.keyword_count > 0 OR md.all_keywords IS NOT NULL
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;

### Explanation of the Query Components:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Computes the number of actors per movie and ranks them by year based on the count of distinct actors.
   - **PopularActors**: Calculates actor appearances across titles and ranks them to identify the actor with the most roles.
   - **MovieDetails**: Gathers movie details along with keyword counts and concatenated keyword strings.

2. **Joins**:
   - Uses left joins between CTEs and main movie details to gather comprehensive data while allowing for NULLs, representing movies with no associated keywords or actors.

3. **Aggregation and Ranking**:
   - Employs `COUNT`, `SUM`, and `STRING_AGG` to handle multiple keywords and actor counts, utilizing window functions to rank movies and actors.

4. **Bizarre Semantics**:
   - The use of counts of NULL (`SUM(mk.keyword IS NOT NULL)`), handling empty keyword cases with potential for unexpected NULL values.

5. **Filtering**:
   - The `WHERE` clause ensures only movies with keywords or associated actors are shown, demonstrating NULL logic.

6. **Ordering**:
   - Orders results by production year descending and keyword count descending for an insightful overview of popular, keyword-rich movies.
