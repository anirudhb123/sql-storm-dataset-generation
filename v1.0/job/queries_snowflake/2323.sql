
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY m.name) as rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        name m ON cn.imdb_id = m.imdb_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Budget', 'Revenue'))
        AND t.production_year IS NOT NULL
),
TopRanked AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    TR.title, 
    TR.production_year, 
    COALESCE(SUM(CASE WHEN mk.keyword_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count,
    COALESCE(MIN(mi.info), 'N/A') AS budget_revenue_info
FROM 
    TopRanked TR
LEFT JOIN 
    movie_keyword mk ON TR.title = (SELECT m.title FROM aka_title m WHERE m.production_year = TR.production_year AND m.title = TR.title)
LEFT JOIN 
    movie_info mi ON (SELECT m.id FROM aka_title m WHERE m.title = TR.title AND m.production_year = TR.production_year) = mi.movie_id
GROUP BY 
    TR.title, TR.production_year
ORDER BY 
    TR.production_year DESC, TR.title;
