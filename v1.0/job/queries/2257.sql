WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
high_budget_movies AS (
    SELECT 
        m.movie_id, 
        m.info 
    FROM 
        movie_info m 
    JOIN 
        info_type it ON m.info_type_id = it.id 
    WHERE 
        it.info = 'budget' AND 
        m.info > '$1000000'
),
final_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        tc.cast_names,
        CASE 
            WHEN hbm.movie_id IS NOT NULL THEN 'High Budget'
            ELSE 'Regular'
        END AS budget_status
    FROM 
        ranked_movies rm
    LEFT JOIN 
        top_cast tc ON rm.movie_id = tc.movie_id
    LEFT JOIN 
        high_budget_movies hbm ON rm.movie_id = hbm.movie_id
)
SELECT 
    title, 
    production_year, 
    cast_count, 
    cast_names, 
    budget_status
FROM 
    final_movies
WHERE 
    budget_status = 'High Budget' OR 
    (production_year = 2022 AND cast_count > 5)
ORDER BY 
    production_year DESC, 
    cast_count DESC;
