
WITH RECURSIVE title_hierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        0 AS level
    FROM
        aka_title t
    WHERE
        t.episode_of_id IS NULL  

    UNION ALL

    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        th.level + 1
    FROM
        aka_title t
    JOIN
        title_hierarchy th ON t.episode_of_id = th.title_id  
),
keyword_agg AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cast_info_enhanced AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.id) AS cast_members,
        MIN(r.role) AS leading_role  
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        th.level AS hierarchy_level,
        k.keywords,
        ci.cast_members,
        ci.leading_role,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        title_hierarchy th
    JOIN 
        aka_title t ON t.id = th.title_id
    LEFT JOIN 
        keyword_agg k ON k.movie_id = t.movie_id
    LEFT JOIN 
        cast_info_enhanced ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')  
)
SELECT 
    md.movie_title,
    md.production_year,
    k.kind AS movie_kind,
    md.hierarchy_level,
    md.keywords,
    md.cast_members,
    md.leading_role,
    md.additional_info
FROM 
    movie_data md
JOIN 
    kind_type k ON k.id = md.kind_id
WHERE 
    md.production_year BETWEEN 1990 AND 2023  
    AND (md.cast_members IS NOT NULL OR md.additional_info IS NOT NULL)  
ORDER BY 
    md.production_year DESC, 
    md.hierarchy_level,
    md.movie_title;
