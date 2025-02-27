WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
movie_info_extended AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords_list
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast') AS cast_names,
    COALESCE(mci.total_companies, 0) AS total_companies,
    COALESCE(mci.company_names, 'No Companies') AS company_names,
    CASE 
        WHEN mh.level > 1 THEN 'Episode'
        ELSE 'Movie'
    END AS type_of_media
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_company_info mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 100;

This SQL query generates a detailed report on movies and episodes, including the following constructs:
- Recursive Common Table Expressions (CTEs) to extract movie hierarchies for episodes.
- Aggregates like `GROUP_CONCAT` to gather keywords and cast names.
- Outer joins to include movies without cast or companies using `LEFT JOIN`.
- Use of `COALESCE` to handle NULL values for counts and names.
- Categorization of media type based on the level of the movie in the hierarchy.
