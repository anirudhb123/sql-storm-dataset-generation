WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mt.id,
        CONCAT(mh.movie_title, ' -> ', mt.title),
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mt.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        c.name AS person_name,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        ci.movie_id, c.name
),
movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, k.keyword
),
final_output AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        md.production_year,
        COALESCE(ca.total_cast, 0) AS total_cast_members,
        COALESCE(md.total_companies, 0) AS total_movie_companies,
        mh.level,
        CASE WHEN md.production_year IS NULL THEN 'Unknown Year' ELSE CAST(md.production_year AS TEXT) END AS production_year_text
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
    LEFT JOIN 
        movie_details md ON mh.movie_id = md.movie_id
)
SELECT 
    movie_title,
    production_year_text,
    total_cast_members,
    total_movie_companies,
    level,
    CONCAT(movie_title, ': ', COALESCE(CAST(total_cast_members AS TEXT), 'None'), ' Cast Members') AS formatted_cast_info
FROM 
    final_output
WHERE 
    total_cast_members > 0 
ORDER BY 
    level ASC, production_year_text DESC;
