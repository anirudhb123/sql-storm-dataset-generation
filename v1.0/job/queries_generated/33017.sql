WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        b.linked_movie_id,
        b.linked_movie_id,
        (SELECT production_year FROM aka_title WHERE id = b.linked_movie_id) AS production_year,
        mh.depth + 1
    FROM 
        movie_link b
    INNER JOIN 
        movie_hierarchy mh ON b.movie_id = mh.movie_id
    WHERE 
        b.linked_movie_id IS NOT NULL
),
movie_details AS (
    SELECT 
        a.id AS movie_id,
        MAX(a.title) AS movie_title,
        MAX(a.production_year) AS release_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS cast_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        a.kind_id = 1 -- assuming '1' is for movies
    GROUP BY 
        a.id
    HAVING 
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) > 5
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.release_year,
    md.total_cast,
    md.aka_names,
    mh.depth,
    CASE 
        WHEN mh.depth IS NULL THEN 'No Hierarchy'
        ELSE 'In Hierarchy'
    END AS hierarchy_status
FROM 
    movie_details md
LEFT JOIN 
    movie_hierarchy mh ON md.movie_id = mh.movie_id
WHERE 
    md.cast_rank <= 3
ORDER BY 
    md.release_year DESC,
    md.total_cast DESC;
