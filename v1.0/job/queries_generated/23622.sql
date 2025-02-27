WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(m.production_year) AS avg_movie_year
    FROM 
        cast_info c
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    GROUP BY 
        c.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalStats AS (
    SELECT 
        a.person_id,
        a.total_movies,
        a.avg_movie_year,
        CASE 
            WHEN a.total_movies > 50 THEN 'Prolific Actor'
            WHEN a.total_movies BETWEEN 21 AND 50 THEN 'Established Actor'
            ELSE 'Emerging Actor' 
        END AS actor_type,
        mk.keywords
    FROM 
        ActorStats a
    LEFT JOIN 
        MovieKeywords mk ON a.total_movies > 20 AND EXISTS (
            SELECT 
                1 
            FROM 
                cast_info c
            WHERE 
                c.person_id = a.person_id
            AND 
                c.movie_id IN (SELECT movie_id FROM movie_keyword)
        )
)
SELECT 
    p.name AS actor_name,
    f.total_movies,
    f.avg_movie_year,
    f.actor_type,
    COALESCE(f.keywords, 'No Keywords') AS keywords
FROM 
    FinalStats f
JOIN 
    aka_name p ON f.person_id = p.person_id
WHERE 
    f.total_movies IS NOT NULL
ORDER BY 
    f.total_movies DESC, 
    f.avg_movie_year ASC NULLS LAST;

### Explanation:
- **CTEs (Common Table Expressions)** are used to break down complex parts of the query for better readability.
- **`RankedMovies`**: Calculates row numbers for movies per production year.
- **`ActorStats`**: Aggregates total movies and average production year for each actor.
- **`MovieKeywords`**: Aggregates keywords associated with each movie.
- **`FinalStats`**: Combines actor statistics and assigns types based on movie counts, with a conditional clause checking for significant movie volume and keywords.
- The final selection retrieves the actor's name, total movie count, average production year, actor type, and associated keywords, ensuring to handle NULLs effectively using `COALESCE`.
- The ordering prioritizes total movies in descending order while taking care of NULL in average years (putting them last). 

This query is designed for performance benchmarking by using a mix of SQL constructs to explore the relationships between actors, movies, and their attributes, while also handling potential NULLs and using window functions effectively.
