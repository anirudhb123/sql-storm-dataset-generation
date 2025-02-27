WITH movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
genre_counts AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
top_movies AS (
    SELECT 
        at.title,
        at.production_year,
        mc.company_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        gc.genres
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        movie_keyword_counts mkc ON at.id = mkc.movie_id
    LEFT JOIN 
        genre_counts gc ON at.id = gc.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title, at.production_year, mc.company_id, mkc.keyword_count, gc.genres
    ORDER BY 
        cast_count DESC, keyword_count DESC
    LIMIT 10
)
SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    t.keyword_count,
    t.genres,
    c.name AS company_name
FROM 
    top_movies t
LEFT JOIN 
    company_name c ON t.company_id = c.id
ORDER BY 
    t.cast_count DESC;

This SQL query performs the following tasks:

1. **CTE for Keyword Counts**: The first Common Table Expression (CTE `movie_keyword_counts`) counts the number of keywords associated with each movie.
  
2. **CTE for Genre Aggregation**: The second CTE (`genre_counts`) aggregates the genres (keywords) associated with each movie into a single string.

3. **CTE for Top Movies**: The third CTE (`top_movies`) combines data from the `aka_title`, `movie_companies`, and `cast_info` tables to find the top movies based on the number of distinct cast members and keywords. It filters movies released from the year 2000 onward.

4. **Final Selection**: The main query selects relevant data from the `top_movies` CTE and joins with the `company_name` table to include the names of the companies associated with the top movies, ordering the results by cast count.

This intricate query allows for the benchmarking of string processing through aggregations and joins while revealing insights into movie production details.
