WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS total_companies,
        COUNT(DISTINCT k.id) AS total_keywords,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        movie_keyword k ON t.id = k.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_companies,
        total_keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_companies,
    tm.total_keywords,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order END) AS avg_cast_order,
    STRING_AGG(DISTINCT a.name, ', ') AS all_actors
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM title WHERE id = mc.movie_id)
LEFT JOIN 
    cast_info c ON mc.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    tm.title, tm.production_year, tm.total_companies, tm.total_keywords
ORDER BY 
    tm.production_year DESC, tm.total_companies DESC;

This SQL query performs the following:

1. It first creates a Common Table Expression (CTE) called `RankedMovies` that counts the number of distinct companies and keywords associated with each movie title, ranked by total companies for each production year.

2. The `TopMovies` CTE retrieves the top 5 movies per year based on the number of associated companies.

3. The final SELECT statement aggregates the results to provide the title, production year, number of companies, number of keywords, average cast order, and a list of all actors connected to those movies.

4. Finally, the output is ordered by production year in descending order and then by the total number of companies associated with each movie in descending order.
