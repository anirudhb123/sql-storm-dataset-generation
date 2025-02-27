WITH movie_aggregate AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

keyword_aggregate AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    ma.title,
    ma.production_year,
    ma.num_cast_members,
    ma.cast_names,
    ka.keywords
FROM 
    movie_aggregate ma
LEFT JOIN 
    keyword_aggregate ka ON ma.movie_id = ka.movie_id
ORDER BY 
    ma.production_year DESC, 
    ma.title ASC;
