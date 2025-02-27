WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
)

SELECT 
    ak.name AS Actor_Name,
    mt.title AS Movie_Title,
    mt.production_year AS Production_Year,
    COALESCE(gender_counts.male_count, 0) AS Male_Count,
    COALESCE(gender_counts.female_count, 0) AS Female_Count,
    MAX(mt.level) OVER (PARTITION BY ak.name) AS Max_Movie_Level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN (
    SELECT 
        ci.movie_id,
        SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        cast_info ci
    JOIN 
        name n ON ci.person_id = n.imdb_id
    GROUP BY 
        ci.movie_id
) gender_counts ON mt.movie_id = gender_counts.movie_id
WHERE 
    ak.md5sum IS NOT NULL
ORDER BY 
    Max_Movie_Level DESC, 
    Actor_Name;
