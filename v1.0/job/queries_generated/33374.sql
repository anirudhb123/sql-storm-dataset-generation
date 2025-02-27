WITH RECURSIVE movie_cast AS (
    SELECT 
        cc.movie_id, 
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names, 
        COUNT(DISTINCT a.id) AS total_cast 
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        cc.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COALESCE(mc.total_cast, 0) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_cast cc ON cc.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, mc.total_cast
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.movie_keyword,
        md.company_names,
        md.total_cast,
        DENSE_RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_by_cast
    FROM 
        movie_details md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.movie_keyword,
    rm.company_names,
    rm.total_cast,
    rm.rank_by_cast
FROM 
    ranked_movies rm
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, rm.rank_by_cast;

### Explanation
- The query starts with a recursive CTE called `movie_cast`, which aggregates the cast names and counts how many distinct cast members are associated with each movie.
- Next, it creates another CTE `movie_details` to gather detailed information about the movies, including titles, production years, keywords, and associated companies. It uses `LEFT JOIN` to connect various tables, ensuring that it includes movies even if they lack some details (like a keyword).
- The `movie_details` CTE groups results to ensure no duplicates and includes a COALESCE function to handle NULL values gracefully for the total cast count.
- Another CTE called `ranked_movies` ranks the movies based on their total cast members for each production year using the `DENSE_RANK` window function.
- Finally, the main `SELECT` retrieves the top 5 movies (by cast size) for each production year and orders the results by production year in descending order and rank.

This query utilizes various SQL constructs including CTEs (both recursive and non-recursive), window functions, aggregate functions, and conditional logic to create a comprehensive view for performance benchmarking.
