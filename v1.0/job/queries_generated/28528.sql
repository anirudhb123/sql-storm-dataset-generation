WITH cte_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.keywords,
    m.companies,
    m.actors
FROM 
    cte_movie_info m
WHERE 
    m.keywords LIKE '%action%' 
    OR m.actors LIKE '%Brad Pitt%'
ORDER BY 
    m.production_year DESC;

This query benchmarks string processing by:
1. Joining several tables to gather comprehensive data about movies, including their titles, production years, associated keywords, production companies, and cast members.
2. Utilizing string aggregation via `GROUP_CONCAT` to compile keywords and actors associated with each movie.
3. Filtering on certain conditions, ensuring only movies from after the year 2000 are included, and further narrowing results to movies associated with the 'action' keyword or featuring 'Brad Pitt'.
4. Ordering the results by production year in descending order to highlight more recent movies.
