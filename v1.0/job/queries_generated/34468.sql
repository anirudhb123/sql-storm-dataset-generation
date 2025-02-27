WITH RECURSIVE movie_cast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.person_role_id = (
            SELECT id FROM role_type WHERE role = 'Director'
        )
    
    UNION ALL
    
    SELECT 
        mc.movie_id,
        mc.person_id,
        m.depth + 1
    FROM 
        cast_info mc
    JOIN 
        movie_cast m ON mc.movie_id = m.movie_id
    WHERE 
        mc.person_role_id IN (
            SELECT id FROM role_type WHERE role IN ('Actor', 'Actress')
        ) AND m.depth < 5
),
movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT mc.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.person_id) DESC) AS rank_by_cast_size
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
aggregated_movies AS (
    SELECT 
        movie_title,
        production_year,
        MAX(keyword) AS predominant_keyword,
        SUM(total_cast) AS total_cast_count,
        COUNT(*) AS movie_count
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
)
SELECT 
    am.production_year,
    COUNT(*) AS total_movies,
    AVG(total_cast_count) AS average_cast_size,
    STRING_AGG(DISTINCT am.predominant_keyword, ', ') AS predominant_keywords
FROM 
    aggregated_movies am
GROUP BY 
    am.production_year
HAVING 
    COUNT(*) > 5
ORDER BY 
    am.production_year DESC;

### Explanation:
- **Recursive CTE (`movie_cast`)**: This part of the query establishes a base case where it selects all movies directed by a person with the role "Director." It then recursively finds all actors (Actors/Actresses) associated with those movies, up to 5 levels deep.
  
- **Main query (`movie_details`)**: Joins the title, movie_keyword, keyword, and the recursive CTE to retrieve movie title, production year, keywords, total cast members, and also ranks the movies by cast size within each production year.

- **Aggregated subquery (`aggregated_movies`)**: Focuses on summarizing total cast members and movie counts for each movie title per year, capturing the maximum keyword used in those titles.

- **Final selection**: Provides a year-wise summary of total movies, average cast size per year, and lists the distinct keywords found in movies with a minimum of 5 titles for each production year, ordered by year. 

This query tests performance across multiple joins, CTEs, aggregate functions, and string operations, making it suitable for benchmarking.
