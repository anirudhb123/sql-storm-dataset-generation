WITH RECURSIVE movie_cast AS (
    SELECT 
        c.movie_id,
        ka.name AS actor_name,
        ka.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
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
company_title AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies,
        STRING_AGG(DISTINCT ct.kind, '; ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
extended_movie_info AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ct.companies, 'No Companies') AS companies,
        COALESCE(ct.company_types, 'No Types') AS company_types
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keywords mk ON mt.id = mk.movie_id
    LEFT JOIN 
        company_title ct ON mt.id = ct.movie_id
),
final_output AS (
    SELECT 
        em.title,
        em.production_year,
        em.keywords,
        em.companies,
        em.company_types,
        mc.actor_name,
        mc.actor_rank
    FROM 
        extended_movie_info em
    LEFT JOIN 
        movie_cast mc ON em.movie_id = mc.movie_id
    WHERE 
        em.production_year >= 2000
    ORDER BY 
        em.production_year DESC,
        mc.actor_rank
)

SELECT 
    fo.title,
    fo.production_year,
    fo.keywords,
    fo.companies,
    fo.company_types,
    fo.actor_name
FROM 
    final_output fo
WHERE 
    fo.actor_name IS NOT NULL
    AND (fo.keywords LIKE '%action%' OR fo.keywords LIKE '%drama%')
ORDER BY 
    fo.production_year DESC,
    fo.title ASC;