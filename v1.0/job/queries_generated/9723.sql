WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year IS NOT NULL
), 
GenreStats AS (
    SELECT 
        kt.keyword AS genre,
        COUNT(DISTINCT m.id) AS movie_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        kt.keyword
), 
CompanyCounts AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS total_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY 
        cn.name
    ORDER BY 
        total_movies DESC
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    gs.genre,
    gs.movie_count,
    gs.avg_production_year,
    cc.company_name,
    cc.total_movies
FROM 
    RankedMovies rm
JOIN 
    GenreStats gs ON rm.movie_id IN (
        SELECT movie_id 
        FROM movie_keyword WHERE keyword_id IN (
            SELECT id FROM keyword WHERE keyword = gs.genre
        )
    )
JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
JOIN 
    CompanyCounts cc ON mc.company_id IN (
        SELECT id FROM company_name WHERE name = cc.company_name
    )
WHERE 
    rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    gs.movie_count DESC;
