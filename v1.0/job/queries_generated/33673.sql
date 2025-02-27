WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 

    UNION ALL 

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
)

SELECT 
    mh.path,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS num_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    COUNT(DISTINCT k.keyword) AS keywords,
    MAX(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info='duration') THEN mi.info 
        ELSE NULL 
    END) AS duration,
    MAX(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info='rating') THEN mi.info 
        ELSE NULL 
    END) AS rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.path, mh.production_year
ORDER BY 
    mh.production_year DESC, num_cast DESC;

### Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE `MovieHierarchy` is created to gather movies from the `aka_title` table that have a production year of 2000 or later and traverse their linked movies up to two levels deep.

2. **Select Statement**: The main query selects various fields from `MovieHierarchy` and performs left joins with `complete_cast`, `cast_info`, `aka_name`, `movie_keyword`, `keyword`, and `movie_info` to gather additional data.

3. **Aggregation**: The query counts the distinct cast members for each movie, uses the `STRING_AGG` function to concatenate actor names, counts distinct keywords, and uses `MAX(CASE...)` constructs to extract specific information about duration and rating.

4. **Filtering**: The filtering logic is applied to pull relevant movie data and it sorts the final results by production year and number of cast members.

5. **NULL Handling**: The `MAX(CASE...)` construction helps deal with NULLs by ensuring that only relevant data is displayed per movie type.

This query is complex, utilizing a variety of SQL constructs, making it suitable for performance benchmarking.
