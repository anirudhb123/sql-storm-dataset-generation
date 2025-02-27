WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        name p ON c.person_id = p.id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_info_stats AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.female_cast,
    rm.male_cast,
    mis.info_details,
    CASE 
        WHEN rm.total_cast IS NULL THEN 'No Cast'
        WHEN rm.total_cast > 0 THEN 'Has Cast'
        ELSE 'Data Error'
    END AS cast_status
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info_stats mis ON rm.movie_id = mis.movie_id
WHERE 
    rm.rank <= 5 
    AND rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year ASC, rm.rank ASC;
