WITH ranked_cast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_id,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
), 
movie_details AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        mk.keyword
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk 
    ON 
        mt.id = mk.movie_id
    WHERE 
        mt.production_year > 2000 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
), 
company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_list
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
char_details AS (
    SELECT 
        cn.name AS character_name,
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        char_name cn
    JOIN 
        cast_info ci ON ci.role_id = cn.id
    GROUP BY 
        cn.name, ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ci.num_companies, 0) AS num_companies,
    COALESCE(ci.companies_list, 'No Companies') AS companies_list,
    COALESCE(cd.character_name, 'Unknown Character') AS character_name,
    cd.num_actors,
    rc.role_rank,
    CASE 
        WHEN rc.role_rank = 1 THEN 'Lead'
        WHEN rc.role_rank IS NULL THEN 'No Cast'
        ELSE 'Supporting'
    END AS role_type
FROM 
    movie_details md
LEFT JOIN 
    company_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    char_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    ranked_cast rc ON md.movie_id = rc.movie_id
WHERE 
    (md.production_year IS NOT NULL OR md.production_year < 2025)
    AND (md.keyword IS NOT NULL OR md.keyword NOT LIKE '%unknown%')
ORDER BY 
    md.production_year DESC NULLS LAST, 
    md.title ASC, 
    role_rank;

