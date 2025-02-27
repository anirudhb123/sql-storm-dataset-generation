WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        coalesced_companies.company_list,
        keyword_list.keywords
    FROM 
        aka_title mt
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            STRING_AGG(DISTINCT cn.name, ', ') AS company_list
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        WHERE 
            cn.country_code IS NOT NULL
        GROUP BY 
            mc.movie_id
    ) AS coalesced_companies ON mt.id = coalesced_companies.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(DISTINCT k.keyword, '; ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) AS keyword_list ON mt.id = keyword_list.movie_id
), ranked_movies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        company_list,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rn
    FROM 
        movie_data
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.company_list,
    rm.keywords,
    CASE 
        WHEN rm.company_list IS NULL THEN 'No Companies Available'
        ELSE rm.company_list 
    END AS formatted_companies,
    CASE 
        WHEN rm.keywords IS NULL THEN (SELECT 'No Keywords Yet' FROM dual)
        ELSE rm.keywords 
    END AS formatted_keywords,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (
        SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id
    )) AS actor_count
FROM 
    ranked_movies rm
WHERE 
    rm.production_year > 2000
    AND EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = rm.movie_id AND cc.status_id IS NOT NULL
    )
ORDER BY 
    rm.production_year DESC, rm.movie_title;
