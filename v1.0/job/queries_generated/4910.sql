WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY b.name) AS rank_name
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
        AND c.country_code IS NOT NULL
),
movie_info_with_notes AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_aggregate,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_name,
    COALESCE(miw.info_aggregate, 'No Info') AS aggregated_info,
    miw.info_count
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info_with_notes miw ON rm.movie_id = miw.movie_id
WHERE 
    rm.rank_name = 1
ORDER BY 
    rm.production_year DESC, 
    rm.rank_name ASC
LIMIT 100;
