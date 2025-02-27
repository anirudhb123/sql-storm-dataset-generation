WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY  at.production_year DESC, at.title) AS movie_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mc.movie_id
),
film_info AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword_info,
        CASE 
            WHEN mt.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS film_category
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    rm.title,
    rm.production_year,
    mc.total_cast,
    mc.cast_names,
    fi.keyword_info,
    fi.film_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_rank = mc.movie_id
JOIN 
    film_info fi ON rm.title = fi.title AND rm.production_year = fi.production_year
WHERE 
    rm.movie_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
