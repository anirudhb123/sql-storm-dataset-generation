WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
info_summary AS (
    SELECT 
        m.movie_id,
        (
            SELECT COUNT(*)
            FROM movie_info mi 
            WHERE mi.movie_id = m.movie_id AND mi.info_type_id = (
                SELECT id FROM info_type WHERE info = 'Summary'
            )
        ) AS summary_count 
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cd.actor_names, 'None') AS actors,
    COALESCE(isum.summary_count, 0) AS summary_info
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    info_summary isum ON rm.movie_id = isum.movie_id
WHERE 
    rm.rn <= 10 -- Get the first 10 movies per year
AND 
    (rm.production_year > 2000 OR cd.actor_count IS NOT NULL)
ORDER BY 
    rm.production_year, rm.title;

WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        ml.movie_id, 
        ml.linked_movie_id, 
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Prequel')
    
    UNION ALL
    
    SELECT 
        ml.movie_id, 
        ml.linked_movie_id, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
)
SELECT 
    mh.movie_id,
    COUNT(mh.linked_movie_id) AS prequel_count
FROM 
    movie_hierarchy mh
GROUP BY 
    mh.movie_id
HAVING 
    COUNT(mh.linked_movie_id) > 0
ORDER BY 
    prequel_count DESC; 

SELECT 
    t.title,
    m.production_year,
    COUNT(DISTINCT wc.id) AS award_count
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id AND mc.company_type_id IS NULL
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    role_type r ON cc.role_id = r.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    (SELECT DISTINCT movie_id, COUNT(DISTINCT info_type_id) AS award_count
     FROM movie_info 
     WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
     GROUP BY movie_id) wc ON t.id = wc.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
AND 
    (mi.info IS NOT NULL OR k.keyword IS NOT NULL OR r.role IS NULL)
GROUP BY 
    t.title, m.production_year
ORDER BY 
    award_count DESC
LIMIT 50;
