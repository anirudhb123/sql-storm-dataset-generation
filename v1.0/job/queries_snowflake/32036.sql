
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        MAX(CASE WHEN ak.name LIKE '%John%' THEN 'Yes' ELSE 'No' END) AS has_john
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        cd.num_cast_members,
        cd.cast_names,
        cd.has_john
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    WHERE 
        mh.production_year > 2000
        AND cd.num_cast_members > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.num_cast_members,
    fm.cast_names,
    COALESCE(cp.kind, 'Unknown') AS company_type
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
ORDER BY 
    fm.production_year DESC, 
    fm.num_cast_members DESC
LIMIT 10;
