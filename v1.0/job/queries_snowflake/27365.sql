
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
),
MostCommonNames AS (
    SELECT 
        a.name AS common_name,
        COUNT(*) AS name_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    ORDER BY 
        name_count DESC
    LIMIT 10
),
KeyMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mi.info
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Synopsis', 'Awards'))
)

SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    mc.common_name,
    kmi.info
FROM 
    RankedTitles rt
JOIN 
    MostCommonNames mc ON LEFT(rt.title, 6) = LEFT(mc.common_name, 6) 
LEFT JOIN 
    KeyMovieInfo kmi ON rt.title_id = kmi.movie_id
WHERE 
    rt.rank = 1 
ORDER BY 
    rt.production_year DESC, rt.title;
