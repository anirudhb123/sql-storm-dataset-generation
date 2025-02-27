WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
movies_with_keywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.cast_count > 5
),
person_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
)

SELECT 
    mw.title,
    mw.production_year,
    COUNT(mw.keyword) AS keyword_count,
    STRING_AGG(DISTINCT pr.role) AS roles_in_movies,
    (SELECT 
        AVG(mt.production_year) 
     FROM 
        aka_title mt 
     WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%') 
     AND 
        mt.production_year < mw.production_year) AS avg_previous_drama_year
FROM 
    movies_with_keywords mw
LEFT JOIN 
    person_roles pr ON mw.title IN (SELECT mt.title FROM aka_title mt WHERE mt.id = pr.movie_id)
WHERE 
    mw.production_year IS NOT NULL
AND 
    mw.keyword IS NOT NULL
GROUP BY 
    mw.title, mw.production_year
HAVING 
    COUNT(mw.keyword) > 2
ORDER BY 
    mw.production_year DESC, keyword_count DESC;
