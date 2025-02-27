WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
top_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.note,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    top.actor_name,
    kt.keyword,
    cp.company_name,
    cp.company_type
FROM 
    ranked_movies m
LEFT JOIN 
    top_cast top ON m.movie_id = top.movie_id AND top.cast_rank <= 3
LEFT JOIN 
    movies_with_keywords kt ON m.movie_id = kt.movie_id
LEFT JOIN 
    company_details cp ON m.movie_id = cp.movie_id
WHERE 
    (m.title LIKE '%Adventure%' OR kt.keyword IS NOT NULL)
    AND (m.production_year BETWEEN 2000 AND 2023)
ORDER BY 
    m.production_year DESC, 
    m.movie_id, 
    top.actor_name;
