WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)

SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    rc.role,
    COUNT(DISTINCT ci.id) AS cast_count,
    COALESCE(g.product_company, 'Unknown') AS production_company
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rc ON ci.person_role_id = rc.id
LEFT JOIN 
    (SELECT 
         mc.movie_id, 
         string_agg(cn.name, ', ') AS product_company
     FROM 
         movie_companies mc
     JOIN 
         company_name cn ON mc.company_id = cn.id
     GROUP BY 
         mc.movie_id) g ON tm.movie_id = g.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, ak.name, rc.role, g.product_company
ORDER BY 
    tm.keyword_count DESC, tm.production_year ASC;

This SQL query benchmarks string processing by performing the following operations:

1. **CTEs for ranking movies**: The first CTE (`RankedMovies`) computes the keyword count for each movie from 2000 onward. The second CTE (`TopMovies`) ranks these movies based on the keyword count.

2. **Main Select Statement**: The main query retrieves details of the top-ranked movies, including the title, production year, actor names, and roles, by joining multiple tables together. It utilizes aggregations to summarize data (such as counting distinct cast members and concatenating company names).

3. **ORDER BY Clause**: The results are ordered by keyword count in descending order and by production year in ascending order, allowing for easy identification of top movies with rich keyword associations, facilitating further string processing analysis.
