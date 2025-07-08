
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id, 
        e.title, 
        e.production_year, 
        mh.level + 1
    FROM 
        aka_title e
        JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
title_with_keywords AS (
    SELECT 
        a.title AS title_name,
        k.keyword,
        a.production_year
    FROM 
        title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
complete_cast_data AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(c.total_cast_members, 0) AS total_cast,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COUNT(mch.linked_movie_id) AS related_movies_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast_data c ON mh.movie_id = c.movie_id
LEFT JOIN 
    title_with_keywords k ON mh.movie_id = k.production_year
LEFT JOIN 
    movie_link mch ON mh.movie_id = mch.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, c.total_cast_members
ORDER BY 
    mh.production_year DESC, mh.title;
