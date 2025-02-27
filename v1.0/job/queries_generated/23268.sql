WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.title IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        person_id,
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 0
),
GenreKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastWithKeywords AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COALESCE(gk.keywords, 'None') AS keywords,
        ct.kind AS cast_type
    FROM 
        cast_info ci
    LEFT JOIN 
        GenreKeywords gk ON ci.movie_id = gk.movie_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
)
SELECT 
    a.person_id,
    COUNT(DISTINCT cm.movie_id) AS total_movies,
    SUM(CASE WHEN gk.keywords IS NOT NULL THEN 1 ELSE 0 END) AS keyword_movies,
    MAX(ct.cast_type) AS cast_type,
    STRING_AGG(DISTINCT mk.keyword, '; ') AS all_keywords,
    MAX(CASE WHEN t.rank_per_year IS NOT NULL THEN t.rank_per_year ELSE 0 END) AS highest_rank_per_year
FROM 
    CastWithKeywords gk
JOIN 
    TopActors a ON gk.person_id = a.person_id
JOIN 
    complete_cast cc ON gk.movie_id = cc.movie_id
LEFT JOIN 
    RankedTitles t ON gk.movie_id = t.title_id
LEFT JOIN 
    movie_keyword mk ON gk.movie_id = mk.movie_id
GROUP BY 
    a.person_id
HAVING 
    COUNT(DISTINCT cm.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_rank
LIMIT 10;

### Explanation of Query Constructs:
1. **Common Table Expressions (CTEs)**:
   - `RankedTitles`: Ranks movie titles by year.
   - `ActorMovieCount`: Aggregates movie count and average production year per actor.
   - `TopActors`: Filters to top actors by movie count.
   - `GenreKeywords`: Gathers keywords for each movie.
   - `CastWithKeywords`: Combines cast info with associated keywords and role types.

2. **Window Functions**:
   - Used to calculate ranks and averages per group of actors.

3. **Aggregations**:
   - `STRING_AGG`: Concatenates keyword strings and distinct counts for movies.

4. **Conditional Logic**:
   - `COALESCE` manages NULLs.

5. **Set Operators and obscure semantics**:
   - Usage of `LEFT JOIN` and `HAVING` creates corner cases where actors may not have associations, retaining them based on conditions.

6. **String Expressions**:
   - `STRING_AGG` serves both for clear concatenation of keywords and organizing search terms.

7. **Complicated Logic**:
   - The use of rankings and conditional aggregations based on multiple joins creates a rich dataset for performance analysis.

This query comprehensively integrates various SQL features, presenting a useful benchmark for performance while exhibiting intricate SQL functionalities.
