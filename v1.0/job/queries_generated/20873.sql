WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_concatenated
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_companies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
complete_cast_info AS (
    SELECT 
        cc.movie_id,
        COUNT(*) AS cast_count,
        ARRAY_AGG(DISTINCT a.actor_name) AS actor_names,
        COALESCE(k.keywords_concatenated, 'No Keywords') AS keywords
    FROM 
        complete_cast cc
    JOIN 
        movie_actors a ON cc.movie_id = a.movie_id
    LEFT JOIN 
        movie_keywords k ON cc.movie_id = k.movie_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    c.cast_count,
    c.actor_names,
    c.keywords
FROM 
    movies_with_companies m
JOIN 
    complete_cast_info c ON m.id = c.movie_id
WHERE 
    m.production_year >= 2000 
    AND (m.company_type IS NULL OR m.company_type LIKE '%Production%')
ORDER BY 
    m.production_year DESC, 
    c.cast_count DESC
LIMIT 50;
This SQL query performs a complex analysis of movies, focusing on production years since 2000. The query uses CTEs to extract:

1. **`movie_actors`**: It ranks actors for each movie based on their order in the cast.
2. **`movie_keywords`**: Aggregates keywords associated with each movie.
3. **`movies_with_companies`**: Retrieves movie titles alongside their production companies and types.
4. **`complete_cast_info`**: Combines cast counts, actor names, and keywords into a single summary.

Finally, the main query joins these CTEs and applies sophisticated filtering criteria, including NULL logic and LIKE comparisons, to extract relevant records for further performance benchmarking, limited to the top 50 entries based on movie production years and cast counts.
