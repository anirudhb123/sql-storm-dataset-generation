WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        SUM(CASE 
            WHEN c.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) OVER (PARTITION BY t.id) AS cast_count,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS row_num
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
),

PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        keyword_count,
        CASE 
            WHEN cast_count > 5 AND keyword_count > 3 THEN 'High'
            WHEN cast_count BETWEEN 3 AND 5 AND keyword_count BETWEEN 1 AND 3 THEN 'Medium'
            ELSE 'Low'
        END AS popularity_rating
    FROM 
        RankedMovies
),

CorrelatedSubquery AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        pm.popularity_rating,
        (SELECT AVG(cast_count) 
         FROM RankedMovies r 
         WHERE r.production_year = pm.production_year) AS avg_cast_count
    FROM 
        PopularMovies pm
    WHERE 
        pm.popularity_rating = 'High'
)

SELECT 
    c.name AS actor_name,
    cm.name AS company_name,
    p.info AS actor_info,
    pm.title AS movie_title,
    pm.production_year,
    pm.popularity_rating,
    pm.avg_cast_count,
    CASE
        WHEN pm.avg_cast_count IS NULL THEN 'No Data' 
        ELSE 'Data Available'
    END AS avg_cast_data_status
FROM 
    complete_cast cc
JOIN 
    aka_name c ON cc.subject_id = c.person_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    CorrelatedSubquery pm ON cc.movie_id = pm.movie_id
WHERE 
    pm.popularity_rating = 'High'
ORDER BY 
    pm.production_year DESC, 
    c.name;

