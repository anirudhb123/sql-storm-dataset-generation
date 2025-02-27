WITH movie_years AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_order
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.production_year
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
actor_names AS (
    SELECT 
        ak.person_id,
        STRING_AGG(a.name, ', ') AS actor_full_names
    FROM 
        aka_name ak
    JOIN 
        name a ON ak.person_id = a.imdb_id
    GROUP BY 
        ak.person_id
)
SELECT 
    m.production_year,
    m.total_cast,
    m.avg_order,
    ki.keywords,
    AN.actor_full_names
FROM 
    movie_years m
LEFT JOIN 
    keyword_info ki ON m.production_year = (SELECT production_year FROM aka_title WHERE id IN (SELECT movie_id FROM movie_info WHERE info_type_id = 1) LIMIT 1)
LEFT JOIN 
    actor_names AN ON AN.person_id IN (SELECT ci.person_id FROM cast_info ci JOIN aka_title t ON ci.movie_id = t.id WHERE t.production_year = m.production_year)
WHERE 
    m.total_cast > 5
ORDER BY 
    m.production_year DESC
LIMIT 10;
