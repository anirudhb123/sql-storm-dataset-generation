WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_keywords AS (
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
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
complete_cast_info AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    mk.keywords,
    cd.company_name,
    cd.company_type,
    cci.total_cast,
    cci.cast_names
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    complete_cast_info cci ON rm.movie_id = cci.movie_id
WHERE 
    rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
