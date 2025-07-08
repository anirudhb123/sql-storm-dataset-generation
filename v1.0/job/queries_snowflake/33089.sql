
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.episode_of_id
),
cast_roles AS (
    SELECT 
        c.movie_id,
        ct.kind AS role,
        COUNT(DISTINCT c.person_id) AS num_cast
    FROM 
        cast_info c
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    GROUP BY 
        c.movie_id, ct.kind
),
combined_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cr.num_cast, 0) AS total_cast,
        mh.depth
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_roles cr ON mh.movie_id = cr.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(mc.company_id) AS num_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    cb.movie_id,
    cb.title,
    cb.production_year,
    cb.total_cast,
    md.keywords,
    md.num_companies,
    CASE 
        WHEN cb.depth > 0 THEN 'Series'
        ELSE 'Film'
    END AS content_type
FROM 
    combined_cast cb
LEFT JOIN 
    movie_details md ON cb.movie_id = md.movie_id
ORDER BY 
    cb.production_year DESC, 
    cb.total_cast DESC
LIMIT 50;
