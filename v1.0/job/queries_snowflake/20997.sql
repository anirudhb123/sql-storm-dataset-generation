
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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id 
    WHERE 
        mh.depth < 5
),
ranked_cast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role, 
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        movie_hierarchy mh 
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.id) > 0
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_selection AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.cast_count,
        mk.keyword_list,
        ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.cast_count DESC) AS year_rank
    FROM 
        filtered_movies f
    LEFT JOIN 
        movie_keywords mk ON f.movie_id = mk.movie_id
    WHERE 
        f.production_year >= 2000
)

SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.cast_count,
    COALESCE(fs.keyword_list, 'No Keywords') AS keywords,
    CASE 
        WHEN fs.year_rank <= 3 THEN 'Top Movie of Year'
        ELSE 'Not Top Movie of Year'
    END AS movie_category,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = fs.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)) AS box_office_count
FROM 
    final_selection fs
WHERE
    fs.year_rank <= 5
ORDER BY 
    fs.production_year DESC, fs.cast_count DESC;
