WITH RecursiveActors AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN title t ON ci.movie_id = t.id
    LEFT JOIN aka_title at ON t.id = at.movie_id
    WHERE ak.name IS NOT NULL
    GROUP BY a.id, ak.name
    HAVING COUNT(ci.movie_id) > 10
),
MovieKeywords AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
MoviesWithRank AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN MovieKeywords mk ON m.id = mk.movie_id
    WHERE EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year < 10
    GROUP BY m.id, m.title, mk.keywords
)
SELECT 
    ma.actor_name,
    mv.title,
    mv.production_year,
    mv.keywords,
    mv.rank_by_cast_count
FROM RecursiveActors ma
JOIN cast_info ci ON ma.person_id = ci.person_id
JOIN MoviesWithRank mv ON ci.movie_id = mv.movie_id
ORDER BY mv.rank_by_cast_count DESC, mv.production_year DESC, ma.actor_name;

### Explanation:
1. **Recursive Common Table Expression (CTE)**: The `RecursiveActors` CTE identifies actors who have participated in more than 10 movies, counting their roles.
2. **Keyword Aggregation**: The `MovieKeywords` CTE aggregates keywords for each movie, providing a list of keywords concatenated into a single string.
3. **Window Function**: The `MoviesWithRank` CTE ranks movies based on the number of distinct actors in each based on the production year, thus allowing fast retrieval of popular and recent films.
4. **Final Selection**: The main query retrieves actor names, associated movie titles, their production years, associated keywords, and ranking by the cast count, ordering results by rank and production year.

This query illustrates complex relationships among actors, movies, and keywords while demonstrating the consolidation of related data using various SQL features including CTEs, JOINs, aggregation, and window functions.
