WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5sum,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)

    UNION ALL

    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5sum,
        h.level + 1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy h ON c.movie_id = (SELECT movie_id FROM complete_cast cc WHERE cc.subject_id = h.person_id LIMIT 1)
    WHERE 
        h.level < 5
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        m.production_year,
        STRING_AGG(DISTINCT mc.note, ', ') AS company_notes
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword_counts kc ON m.id = kc.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, kc.keyword_count, m.production_year
)
SELECT 
    m.title,
    m.production_year,
    m.keyword_count,
    STRING_AGG(DISTINCT ah.actor_name ORDER BY ah.level) AS actors,
    m.company_notes
FROM 
    movie_info_aggregated m
LEFT JOIN 
    actor_hierarchy ah ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = m.movie_id 
        AND ci.person_id = ah.person_id
    )
GROUP BY 
    m.title, m.production_year, m.keyword_count, m.company_notes
ORDER BY 
    m.production_year DESC, 
    m.keyword_count DESC, 
    m.title;
