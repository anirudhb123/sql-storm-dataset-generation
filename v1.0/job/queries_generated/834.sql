WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        c.name AS company_name,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        title m ON a.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),
CoActors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TitleCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_title,
    rm.company_name,
    COALESCE(cc.total_cast, 0) AS total_cast,
    tc.keyword_count,
    rm.production_year,
    CASE 
        WHEN rm.year_rank < 6 THEN 'Top Films of the Year'
        ELSE 'Other Films'
    END AS film_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CoActors cc ON rm.movie_title = (SELECT title FROM aka_title WHERE movie_id = cc.movie_id LIMIT 1)
LEFT JOIN 
    TitleCounts tc ON rm.production_year = (SELECT production_year FROM title WHERE id = tc.movie_id LIMIT 1)
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    total_cast DESC;
