WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(cc.id) AS cast_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_role
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cm ON mt.id = cm.movie_id
    LEFT JOIN 
        cast_info ci ON cm.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mt.id, mt.title
),
filtered_movies AS (
    SELECT *, 
           RANK() OVER (ORDER BY cast_count DESC, title ASC) AS movie_rank
    FROM 
        ranked_movies
    WHERE 
        production_year IS NOT NULL AND
        cast_count > 5 
),
complex_queries AS (
    SELECT 
        fm.movie_id,
        fm.title, 
        fm.cast_count,
        COALESCE(NULLIF(fm.avg_has_role, 0), -1) AS is_avg_has_role,
        STRING_AGG(DISTINCT an.name, ', ') AS all_cast_names,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        filtered_movies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id 
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        fm.movie_id, fm.title, fm.cast_count, fm.avg_has_role
    HAVING 
        COUNT(DISTINCT ci.role_id) > 0 AND
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) = 1
    ORDER BY 
        movie_rank
)
SELECT 
    title,
    cast_count,
    all_cast_names,
    keyword_count,
    CASE 
        WHEN keyword_count > 3 THEN 'Highly Keyworded'
        WHEN keyword_count BETWEEN 1 AND 3 THEN 'Moderately Keyworded'
        ELSE 'Low Keyword Count'
    END AS keyword_category,
    CASE 
        WHEN is_avg_has_role = -1 THEN 'No Roles Assigned'
        ELSE 'Roles Assigned'
    END AS role_status
FROM 
    complex_queries
WHERE 
    title NOT LIKE '%Episode%' -- Exclude episodic titles
    AND title IS NOT NULL
    AND LENGTH(title) - LENGTH(REPLACE(title, ' ', '')) >= 3 -- More than 3 words
ORDER BY 
    cast_count DESC;
