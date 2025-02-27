WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        title m ON a.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
ranked_companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.keywords,
    rc.companies,
    rc.company_types,
    rm.cast_count,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.movie_id) AS complete_cast_count
FROM 
    ranked_movies rm
LEFT JOIN 
    ranked_companies rc ON rm.movie_id = rc.movie_id
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
