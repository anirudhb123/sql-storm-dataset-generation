WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON mk.movie_id = at.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        k.keyword LIKE '%Action%'
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS unique_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
FinalResults AS (
    SELECT 
        rt.title,
        rt.production_year,
        cd.actor_name,
        cd.unique_actors,
        CONCAT(rt.title, ' (', rt.production_year, ') - Starring: ', STRING_AGG(cd.actor_name, ', ')) AS full_description
    FROM 
        RankedTitles rt
    JOIN 
        CastDetails cd ON cd.movie_id = (SELECT movie_id FROM aka_title WHERE title = rt.title)
    WHERE 
        rt.title_rank <= 5
    GROUP BY 
        rt.title, rt.production_year, cd.actor_name
)
SELECT 
    full_description
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    LENGTH(full_description) ASC;

The above query performs advanced string processing and manipulation with several key elements to benchmark for performance. It does the following:

1. **Common Table Expressions (CTEs)**: The query uses CTEs to break down the tasks into manageable sections.
2. **Ranking Titles**: It ranks movie titles based on their length for each production year, particularly focusing on action-related keywords.
3. **Count Unique Actors**: It aggregates data about the unique actors in each movie, demonstrating string-processing with the `STRING_AGG()` function.
4. **Final Output**: Combines all information into a full description, showcasing SQL's string manipulation capabilities.
5. **Ordering**: Sorts the final output based on the production year and length of the descriptions. 

This enables effective benchmarking for SQL string processing while also returning insightful data regarding action movies and their casts.
