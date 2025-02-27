WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
movie_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
directors AS (
    SELECT 
        ci.movie_id,
        ak.name AS director_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    COALESCE(d.director_name, 'Unknown') AS director_name,
    mwk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    directors d ON rm.title = d.movie_id
LEFT JOIN 
    movie_with_keywords mwk ON rm.title = mwk.title
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
