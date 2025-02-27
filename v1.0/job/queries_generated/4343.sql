WITH RankedMovies AS (
    SELECT 
        a.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.title) AS year_rank,
        COUNT(m.id) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
)
SELECT 
    r.production_year, 
    AVG(r.movie_count) AS average_movies_per_year,
    STRING_AGG(DISTINCT r.title, ', ') AS movie_titles,
    COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT m.movie_id FROM complete_cast m)), 0) AS total_movie_info_records,
    SUM(CASE WHEN m.company_id IS NOT NULL THEN 1 ELSE 0 END) AS companies_involved,
    MAX(r.year_rank) FILTER (WHERE r.year_rank > 10) AS max_rank_above_ten
FROM 
    RankedMovies r
LEFT JOIN 
    movie_companies m ON m.movie_id = (SELECT movie_id FROM complete_cast cc WHERE cc.movie_id = r.movie_id LIMIT 1)
GROUP BY 
    r.production_year
HAVING 
    AVG(r.movie_count) > 5
ORDER BY 
    r.production_year DESC;
