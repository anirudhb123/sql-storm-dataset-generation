WITH RECURSIVE movie_cast AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
grouped_cast AS (
    SELECT 
        mc.movie_id,
        MAX(mc.role_order) AS max_role_order,
        COUNT(mc.person_id) AS total_cast
    FROM 
        movie_cast mc
    GROUP BY 
        mc.movie_id
),
extended_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ki.keyword, 'None') AS keyword,
        COALESCE(cn.name, 'Unknown') AS company_name,
        g.total_cast,
        g.max_role_order
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        grouped_cast g ON m.id = g.movie_id
)
SELECT 
    e.movie_id,
    e.title,
    e.keyword,
    e.company_name,
    e.total_cast,
    e.max_role_order,
    CASE 
        WHEN e.max_role_order > 5 THEN 'Ensemble Cast'
        WHEN e.max_role_order BETWEEN 3 AND 5 THEN 'Significant Role'
        ELSE 'Minor Role'
    END AS role_type_descriptor,
    (SELECT COUNT(DISTINCT a.id)
     FROM aka_title a
     JOIN movie_link ml ON a.movie_id = ml.movie_id
     WHERE ml.linked_movie_id = e.movie_id) AS linked_movies_count
FROM 
    extended_info e
WHERE 
    e.total_cast > 0
ORDER BY 
    e.production_year DESC NULLS LAST, 
    e.total_cast DESC;

