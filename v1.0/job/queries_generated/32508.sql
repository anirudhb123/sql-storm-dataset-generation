WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        m.id,
        m.title,
        COUNT(c.id) AS cast_count,
        AVG(p.age) AS average_age
    FROM 
        aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN (
        SELECT 
            pi.person_id,
            EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM pi.info) AS age
        FROM 
            person_info pi
        WHERE 
            pi.info_type_id = (SELECT id FROM info_type WHERE info = 'BirthYear')
    ) p ON c.person_id = p.person_id
    GROUP BY 
        m.id
    HAVING 
        CAST(COUNT(c.id) AS FLOAT) / NULLIF(COUNT(DISTINCT m.id), 0) > 0.5
),
KeywordCounts AS (
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
FinalResult AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        kc.keyword_count,
        m.get_value AS episode_related
    FROM 
        TopMovies tm
    LEFT JOIN KeywordCounts kc ON tm.id = kc.movie_id
    LEFT JOIN MovieHierarchy m ON tm.id = m.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    COALESCE(fr.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN fr.episode_related IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS is_episode
FROM 
    FinalResult fr
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC;
