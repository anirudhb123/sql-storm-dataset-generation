
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
selected_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ka.name,
        ka.person_id
    FROM 
        aka_title at
    INNER JOIN 
        cast_info ci ON at.id = ci.movie_id
    INNER JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
        AND ka.name IS NOT NULL
        AND (SELECT COUNT(*) FROM actor_movie_counts amc WHERE amc.person_id = ka.person_id) > 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    st.title,
    st.production_year,
    LISTAGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Latest Movie'
        ELSE 'Older Movie'
    END AS movie_classification
FROM 
    selected_titles st
LEFT JOIN 
    ranked_movies rm ON st.production_year = rm.production_year
LEFT JOIN 
    movie_keywords mk ON st.title_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON st.title_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    st.title, 
    st.production_year, 
    rm.year_rank, 
    mk.keywords
HAVING 
    COUNT(DISTINCT ak.name) > 2
ORDER BY 
    st.production_year DESC;
