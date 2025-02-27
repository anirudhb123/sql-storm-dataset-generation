WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a 
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
keyword_counts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk 
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        kc.keyword_count,
        CASE 
            WHEN rm.cast_count > 5 AND kc.keyword_count > 3 THEN 'Popular'
            WHEN rm.cast_count <= 5 AND kc.keyword_count <= 3 THEN 'Indie'
            ELSE 'Average'
        END AS movie_category
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_counts kc ON rm.title = kc.movie_id
    WHERE 
        rm.rank_by_year <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.keyword_count,
    fm.movie_category
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;

WITH most_common_names AS (
    SELECT 
        n.name,
        COUNT(DISTINCT c.person_id) AS name_count
    FROM 
        name n 
    JOIN 
        cast_info c ON n.id = c.person_role_id
    GROUP BY 
        n.name
    HAVING 
        COUNT(DISTINCT c.person_id) > 2
)
SELECT 
    DISTINCT fm.title, 
    mc.name
FROM 
    filtered_movies fm
JOIN 
    most_common_names mc ON fm.cast_count > 10
WHERE 
    mc.name IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    mc.name;
