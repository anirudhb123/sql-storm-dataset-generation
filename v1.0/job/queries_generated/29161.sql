WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        cast_names,
        keywords,
        companies,
        ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY production_year DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.kind_id,
    rm.rank,
    rm.cast_names,
    rm.keywords,
    rm.companies
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.kind_id, 
    rm.production_year DESC;
