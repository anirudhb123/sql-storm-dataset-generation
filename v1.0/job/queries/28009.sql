WITH movie_title AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mt.movie_id,
    mt.title,
    mt.production_year,
    cd.total_cast_members,
    cd.cast_names,
    co.total_companies,
    co.company_names,
    mt.movie_keyword
FROM 
    movie_title mt
LEFT JOIN 
    cast_details cd ON mt.movie_id = cd.movie_id
LEFT JOIN 
    company_details co ON mt.movie_id = co.movie_id
WHERE 
    mt.movie_keyword IS NOT NULL
ORDER BY 
    mt.production_year DESC, 
    mt.title;
