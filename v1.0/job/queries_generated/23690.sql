WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ca.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        cs.total_cast,
        cs.actor_names,
        r.year_rank,
        r.total_movies
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_summary cs ON r.title = cs.movie_id
    JOIN 
        aka_title tm ON tm.title = r.title
)
SELECT 
    md.production_year,
    COUNT(DISTINCT md.title) AS movie_count,
    AVG(md.total_cast)::numeric(10, 2) AS average_cast_size,
    MAX(md.actor_names) AS most_common_actors,
    STRING_AGG(md.title, ' | ') AS movie_list
FROM 
    movie_details md
GROUP BY 
    md.production_year
HAVING 
    COUNT(DISTINCT md.title) > 3
ORDER BY 
    md.production_year DESC
LIMIT 10;

This query does the following:

1. **CTEs Definition:**
   - `ranked_movies`: Ranks movies by `production_year`, counting them and providing a year rank.
   - `cast_summary`: Summarizes cast information per movie, aggregating names and counting distinct actors.
   - `movie_details`: Joins the ranked movies and cast summary to gather detailed insights about movies.

2. **Main Query**: 
   - Grouping by `production_year` to count movies, averaging cast sizes, obtaining most common actor names, and listing titles.
   - Uses `HAVING` to filter for years with more than 3 distinct movies.
   - Orders results descending by year while limiting results to the latest 10 years.

This complex query structure exhibits performance benchmarking using CTEs, aggregations, and joins to produce insightful metrics while adhering to the benchmarks set in the schema.
