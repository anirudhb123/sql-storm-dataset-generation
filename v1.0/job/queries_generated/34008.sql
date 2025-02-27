WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        CAST(NULL AS VARCHAR(255)) AS parent_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        p.movie_title AS parent_title,
        level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy p ON e.episode_of_id = p.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(mk.keyword_count) AS total_keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            COUNT(mk.keyword_id) AS keyword_count
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.level
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.company_count,
        tm.total_keywords
    FROM 
        TopMovies tm
    WHERE 
        tm.company_count > 1 AND tm.total_keywords > 5
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.company_count,
    fm.total_keywords,
    COALESCE(cast_info.note, 'No additional information') AS additional_info,
    CASE 
        WHEN fm.company_count > 5 THEN 'High Production'
        WHEN fm.company_count BETWEEN 2 AND 5 THEN 'Moderate Production'
        ELSE 'Low Production'
    END AS production_level
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ON fm.movie_id = cast_info.movie_id
WHERE 
    cast_info.person_role_id IS NOT NULL
ORDER BY 
    fm.total_keywords DESC, 
    fm.movie_title;
