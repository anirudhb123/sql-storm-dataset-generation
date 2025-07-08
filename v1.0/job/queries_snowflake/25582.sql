
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(count(DISTINCT mc.company_id), 0) AS company_count,
        COALESCE(count(DISTINCT mk.keyword_id), 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title ASC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
highlighted_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.company_count,
        r.keyword_count
    FROM 
        ranked_movies r
    WHERE 
        r.rank <= 5  
),
cast_details AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        MIN(ak.id) AS first_actor_id  
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    hm.company_count,
    hm.keyword_count,
    cd.cast_names,
    ak.name AS first_actor_name
FROM 
    highlighted_movies hm
LEFT JOIN 
    cast_details cd ON hm.movie_id = cd.movie_id
LEFT JOIN 
    aka_name ak ON cd.first_actor_id = ak.id
WHERE 
    hm.production_year >= 2000
ORDER BY 
    hm.production_year DESC, hm.title ASC;
