WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COALESCE(c.name, 'Unknown') AS director_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year IS NOT NULL
), TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.director_name, 
        rm.rank,
        rm.keyword_count,
        RANK() OVER (ORDER BY rm.keyword_count DESC) AS overall_rank
    FROM RankedMovies rm
    WHERE rm.rank <= 5
)
SELECT 
    t.title, 
    t.production_year,
    t.director_name,
    t.keyword_count,
    CASE 
        WHEN t.keyword_count > 5 THEN 'Highly Tagged'
        WHEN t.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Sparsely Tagged' 
    END AS tagging_category
FROM TopMovies t
WHERE t.overall_rank <= 10
ORDER BY t.production_year DESC, t.keyword_count DESC;
