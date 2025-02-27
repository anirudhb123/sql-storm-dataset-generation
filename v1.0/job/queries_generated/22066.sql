WITH Recursive_CTE AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS unique_cast_count,
        COUNT(DISTINCT mk.keyword) AS unique_keyword_count
    FROM 
        cast_info c
    JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    GROUP BY 
        c.movie_id
),
Movie_Info AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(MIN(mf.info), 'No Info') AS movie_info
    FROM 
        title m
    LEFT JOIN 
        movie_info mf ON m.id = mf.movie_id AND mf.note IS NULL
    GROUP BY 
        m.id
),
Ranked_Movies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.movie_info,
        rc.unique_cast_count,
        rc.unique_keyword_count,
        RANK() OVER (ORDER BY rc.unique_cast_count DESC) AS cast_rank,
        RANK() OVER (ORDER BY rc.unique_keyword_count DESC) AS keyword_rank
    FROM 
        Movie_Info m
    JOIN 
        Recursive_CTE rc ON m.movie_id = rc.movie_id
),
Combined_Rank AS (
    SELECT 
        movie_id,
        movie_title,
        movie_info,
        unique_cast_count,
        unique_keyword_count,
        cast_rank,
        keyword_rank,
        (cast_rank + keyword_rank) AS total_rank
    FROM 
        Ranked_Movies
    WHERE 
        movie_info IS NOT NULL OR unique_cast_count = 0
)
SELECT 
    cr.movie_id,
    cr.movie_title,
    cr.movie_info,
    cr.unique_cast_count,
    cr.unique_keyword_count,
    cr.total_rank,
    CASE 
        WHEN cr.total_rank <= 10 THEN 'Top Movie'
        WHEN cr.total_rank BETWEEN 11 AND 50 THEN 'Notable Movie'
        ELSE 'Minor Movie'
    END AS movie_category,
    (SELECT AVG(unique_cast_count) FROM Combined_Rank) AS avg_unique_cast_count,
    (SELECT COUNT(*) FROM Combined_Rank WHERE movie_info LIKE '%reboot%') AS reboot_count,
    CASE 
        WHEN MAX(m.time) IS NULL THEN 'No Release Year'
        ELSE MAX(m.production_year) 
    END AS last_release_year
FROM 
    Combined_Rank cr
LEFT JOIN 
    aka_title m ON cr.movie_id = m.movie_id
GROUP BY 
    cr.movie_id, cr.movie_title, cr.movie_info, 
    cr.unique_cast_count, cr.unique_keyword_count, cr.total_rank
ORDER BY 
    cr.total_rank, cr.movie_title
LIMIT 50;
