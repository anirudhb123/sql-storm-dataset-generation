WITH top_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        aka_title at
        JOIN complete_cast cc ON at.id = cc.movie_id
    GROUP BY 
        at.title, at.production_year
    HAVING 
        COUNT(DISTINCT cc.person_id) > 5
),
movie_keywords AS (
    SELECT 
        am.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title am
        JOIN movie_keyword mk ON am.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        am.title
),
movie_info AS (
    SELECT 
        am.title,
        mi.info
    FROM 
        aka_title am
        LEFT JOIN movie_info mi ON am.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    mi.info AS box_office_info,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.cast_count DESC) AS rank
FROM 
    top_movies t
    LEFT JOIN movie_keywords mk ON t.title = mk.title
    LEFT JOIN movie_info mi ON t.title = mi.title
ORDER BY 
    t.production_year DESC, rank;
