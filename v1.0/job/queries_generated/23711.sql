WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
RecentMoviesWithActors AS (
    SELECT 
        c.movie_id,
        c.person_id,
        COALESCE(n.name, 'Unknown') AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        c.note IS NULL
),
MovieStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT a.person_id) AS total_actors,
        AVG(r.title_rank) AS avg_title_rank
    FROM 
        RecentMoviesWithActors m
    JOIN 
        RankedTitles r ON m.movie_id = r.title_id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        m.movie_id,
        r.title,
        COALESCE(s.total_actors, 0) AS actor_count,
        COALESCE(s.avg_title_rank, 0) AS average_rank
    FROM 
        RankedTitles r
    LEFT JOIN 
        MovieStats s ON r.title_id = s.movie_id
)

SELECT 
    f.movie_id,
    f.title,
    f.actor_count,
    f.average_rank,
    CASE 
        WHEN f.actor_count > 10 THEN 'Ensemble Cast'
        WHEN f.actor_count IS NULL THEN 'No Actors'
        ELSE 'Small Cast'
    END AS cast_type
FROM 
    FinalResults f
WHERE 
    f.average_rank <> (SELECT AVG(average_rank) FROM FinalResults) -- Exclude average movies
ORDER BY 
    f.actor_count DESC, f.average_rank ASC;

### Explanation:
1. **CTEs (Common Table Expressions)** are used to break down the query into manageable parts.
   - **RankedTitles** ranks titles within their production year.
   - **RecentMoviesWithActors** collects movie ID and list of actors, filtering out any notes and providing a fall-back name if not found.
   - **MovieStats** computes the total number of unique actors per movie and calculates the average title rank from the previous CTE.
   - **FinalResults** combines movie data with statistics derived in the previous CTE.

2. **Main Selection** assembles the final result set while classifying movies based on their actor counts.

3. **Filtering** is done to exclude movies with an average rank equal to the average of all movies.

4. **Sorting** ensures the results are presented in a meaningful way, first by actor count, then by average rank.

This SQL query utilizes a variety of constructs, including CTEs, window functions, outer joins, and case statements, showcasing complex logic and expression evaluations within the Join Order Benchmark schema.
