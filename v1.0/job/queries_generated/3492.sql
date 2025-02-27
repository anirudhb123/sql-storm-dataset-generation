WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS total_cast,
    COALESCE(cd.company_names, 'No Companies') AS companies,
    COALESCE(cd.company_types, 'No Types') AS types,
    COALESCE(kc.keyword_count, 0) AS total_keywords
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    keyword_count kc ON md.movie_id = kc.movie_id
WHERE 
    (md.production_year BETWEEN 2005 AND 2015) 
    OR (md.cast_count > 5 AND kc.keyword_count > 3)
ORDER BY 
    md.production_year DESC,
    md.title ASC;
