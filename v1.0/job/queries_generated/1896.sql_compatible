
WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT CAST(c.id AS TEXT), ', ') AS cast_ids,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
    GROUP BY 
        t.title, t.production_year
),
actor_info AS (
    SELECT 
        a.name,
        a.person_id,
        i.info AS actor_bio,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY i.id DESC) AS rn
    FROM 
        aka_name a
    LEFT JOIN 
        person_info i ON a.person_id = i.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    md.title,
    md.production_year,
    ai.name AS actor_name,
    ai.actor_bio,
    md.cast_ids,
    md.total_cast,
    COALESCE(md.keywords, 'No Keywords') AS keywords
FROM 
    movie_details md
LEFT JOIN 
    actor_info ai ON ai.person_id = ANY(STRING_TO_ARRAY(md.cast_ids, ', ')::integer[])
WHERE 
    ai.rn = 1
ORDER BY 
    md.production_year DESC, 
    md.title;
