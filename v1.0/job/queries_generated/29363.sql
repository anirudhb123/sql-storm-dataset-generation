WITH movie_actors AS (
    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        ak.surname_pcode,
        ai.movie_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.id) AS total_roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ai ON ak.person_id = ai.person_id
    JOIN 
        aka_title at ON ai.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ai.person_id, ak.name, ak.surname_pcode, ai.movie_id, at.title, at.production_year
),

keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ',') AS keyword_ids
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

detailed_info AS (
    SELECT 
        ma.actor_name,
        ma.movie_title,
        ma.production_year,
        ks.keyword_ids,
        ma.total_roles
    FROM 
        movie_actors ma
    LEFT JOIN 
        keyword_summary ks ON ma.movie_id = ks.movie_id
)

SELECT 
    di.actor_name,
    di.movie_title,
    di.production_year,
    di.total_roles,
    COALESCE(di.keyword_ids, 'No Keywords') AS keyword_list
FROM 
    detailed_info di
WHERE 
    di.total_roles > 1 
ORDER BY 
    di.production_year DESC, di.total_roles DESC;

