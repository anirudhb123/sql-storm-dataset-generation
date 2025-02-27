WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(mk.keyword_count, 0) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
CombinedData AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        am.actor_name,
        ROW_NUMBER() OVER (PARTITION BY tm.movie_id ORDER BY am.actor_name) AS actor_rank
    FROM 
        TopMovies tm
    LEFT JOIN ActorMovies am ON tm.movie_id = am.movie_id
),
FinalResults AS (
    SELECT 
        cd.movie_id,
        cd.title,
        cd.production_year,
        STRING_AGG(cd.actor_name, ', ') AS actor_list
    FROM 
        CombinedData cd
    WHERE 
        cd.actor_name IS NOT NULL
    GROUP BY 
        cd.movie_id, cd.title, cd.production_year
),
KeywordSummary AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_list,
    COALESCE(ks.keywords, 'No keywords') AS keywords
FROM 
    FinalResults fr
LEFT JOIN 
    KeywordSummary ks ON fr.movie_id = ks.movie_id
ORDER BY 
    fr.production_year DESC, fr.title;

### Explanation:
1. **CTEs Usage**: Multiple Common Table Expressions (CTEs) are employed to establish a structured query approach:
   - **RankedMovies**: Ranks movies based on the number of keywords associated with them within each production year, limiting to those years with available data.
   - **TopMovies**: Filters out only the top 5 ranked movies for each production year.
   - **ActorMovies**: Collects actor names for each movie based on cast information.
   - **CombinedData**: Combines movie data with the corresponding actor data while numbering the actors per movie.
   - **FinalResults**: Aggregates actor names into a comma-separated list for each movie.

2. **String Aggregation**: Uses `STRING_AGG` to create lists of actor names and keywords, showcasing how to concatenate strings from multiple rows into one.

3. **Outer Joins**: Implements `LEFT JOIN` in several places to ensure that movies with no associated actor or keywords are still included in the final results.

4. **NULL Handling**: COALESCE is used to manage potential NULL values for keywords and actors, replacing them with sensible defaults in the output.

5. **Unusual SQL Semantics**: The usage of both ranking functions and random aggregations coupled with complex joins highlights some of the more peculiar aspects of SQL querying.

6. **Ordering Results**: Final output is sorted primarily by production year descending and then by movie title, ensuring a logical and user-friendly result ordering. 

This SQL query exemplifies a comprehensive approach to SQL performance benchmarking using nested structures and analytical functions.
