
WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS rank_by_length
    FROM 
        aka_title at
),
person_titles AS (
    SELECT 
        akn.person_id,
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
    WHERE 
        akn.name ILIKE '%Smith%'  
),
title_info AS (
    SELECT 
        pt.person_id,
        pt.title,
        pt.production_year,
        kt.kind AS movie_kind,
        ki.keyword AS movie_keyword
    FROM 
        person_titles pt
    JOIN 
        title t ON pt.title_id = t.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        pt.production_year >= 2000 
        AND pt.production_year < 2023
)
SELECT 
    pt.person_id,
    COUNT(*) AS total_movies,
    STRING_AGG(DISTINCT pt.title, ', ') AS titles,
    STRING_AGG(DISTINCT pt.movie_kind, ', ') AS kinds,
    STRING_AGG(DISTINCT pt.movie_keyword, ', ') AS keywords
FROM 
    title_info pt
GROUP BY 
    pt.person_id
ORDER BY 
    total_movies DESC
LIMIT 10;
