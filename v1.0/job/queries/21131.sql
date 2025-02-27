WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        array_agg(DISTINCT ak.name) AS aka_names, 
        count(DISTINCT ci.id) AS cast_count,
        CASE 
            WHEN mt.production_year IS NULL THEN 'Unknown Year'
            WHEN mt.production_year >= 2000 THEN 'Modern Era'
            ELSE 'Classic Era'
        END AS movie_era
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ' | ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        array_agg(DISTINCT cn.name) AS companies,
        array_agg(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_result AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.aka_names,
        md.cast_count,
        md.movie_era,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.companies, ARRAY['No Companies']) AS companies,
        COALESCE(ci.company_types, ARRAY['No Types']) AS company_types
    FROM 
        movie_details md
    LEFT JOIN 
        movie_keywords mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        company_info ci ON md.movie_id = ci.movie_id
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.aka_names,
    fr.cast_count,
    fr.movie_era,
    fr.keywords,
    fr.companies,
    fr.company_types,
    LEAD(fr.movie_title) OVER (ORDER BY fr.production_year) AS next_movie_title,
    COUNT(*) OVER () AS total_movies
FROM 
    final_result fr
WHERE 
    fr.cast_count > 5 
    OR fr.keywords LIKE '%action%'
ORDER BY 
    fr.production_year DESC 
LIMIT 10;