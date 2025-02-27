WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id
),
title_info AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        mt.cast_names,
        mt.keywords,
        mt.company_count,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info::numeric END), 0) AS total_budget,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box_office') THEN mi.info::numeric END), 0) AS total_box_office
    FROM 
        movie_details mt
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year, mt.cast_names, mt.keywords, mt.company_count
)
SELECT 
    ti.title,
    ti.production_year,
    ti.cast_names,
    ti.keywords,
    ti.company_count,
    ti.total_budget,
    ti.total_box_office
FROM 
    title_info ti
ORDER BY 
    ti.total_box_office DESC, 
    ti.production_year DESC;
