WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
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
    GROUP BY 
        t.id
),
person_information AS (
    SELECT 
        p.id AS person_id,
        p.name,
        info.info AS biography
    FROM 
        name p
    LEFT JOIN 
        person_info info ON p.id = info.person_id
    WHERE 
        info.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
),
ranking AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    r.title,
    r.production_year,
    r.total_cast,
    p.name AS actor_name,
    p.biography,
    r.keywords
FROM 
    ranking r
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    person_information p ON ci.person_id = p.person_id
WHERE 
    r.rank <= 5 AND
    r.production_year IS NOT NULL
ORDER BY 
    r.production_year DESC, r.total_cast DESC;
