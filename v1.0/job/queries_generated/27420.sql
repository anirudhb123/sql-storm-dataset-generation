WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        array_agg(DISTINCT ak.name) AS aka_names,
        array_agg(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT m.info_type_id) AS info_type_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    GROUP BY 
        t.id
), ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        cast_names,
        keyword_count,
        company_count,
        info_type_count,
        RANK() OVER (ORDER BY keyword_count DESC, company_count DESC, info_type_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.cast_names,
    rm.keyword_count,
    rm.company_count,
    rm.info_type_count
FROM 
    ranked_movies rm
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.rank
LIMIT 10;
