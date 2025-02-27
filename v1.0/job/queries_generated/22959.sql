WITH RECURSIVE popular_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS popularity_rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info mi ON a.movie_id = mi.movie_id
    JOIN 
        keyword k ON mi.info = k.keyword
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info_idx mii ON a.movie_id = mii.movie_id
    LEFT JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
        AND (cn.country_code IS NOT NULL OR mii.info LIKE '%Award%')
    GROUP BY 
        a.id, a.title, a.production_year
    HAVING 
        (COUNT(DISTINCT ci.person_id) > 5 OR a.title ILIKE '%Matrix%')
), movie_statistics AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
        AVG(CASE WHEN mi.info LIKE '%Budget%' THEN 
            CAST(SUBSTRING(mi.info FROM '[0-9]+') AS INTEGER) ELSE NULL END) AS avg_budget
    FROM 
        popular_movies pm
    JOIN 
        cast_info ci ON pm.movie_id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_info mi ON pm.movie_id = mi.movie_id
    GROUP BY 
        pm.movie_id, pm.title, pm.production_year
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    COALESCE(ms.avg_budget, 'N/A') AS avg_budget,
    CASE 
        WHEN ms.total_cast > 10 THEN 'Ensemble Cast'
        WHEN ms.total_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_size_category,
    LEAD(ms.avg_budget) OVER (ORDER BY ms.production_year) AS next_budget_value
FROM 
    movie_statistics ms
WHERE 
    ms.title IS NOT NULL 
    AND ms.title NOT LIKE '%deleted%'
ORDER BY 
    ms.production_year DESC, ms.total_cast DESC;
