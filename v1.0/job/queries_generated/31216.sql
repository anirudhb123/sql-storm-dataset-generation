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
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link mt
    INNER JOIN aka_title t ON mt.linked_movie_id = t.id
    INNER JOIN MovieHierarchy mh ON mt.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    MAX(ci.note) AS latest_cast_note,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mh.production_year AS TEXT)
    END AS production_year_display,
    ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS ranking,
    AVG(julianday('now') - julianday(mh.production_year || '-01-01')) AS avg_age
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.level, ranking;
