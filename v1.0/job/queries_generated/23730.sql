WITH movie_data AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.person_id,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_order,
        CASE 
            WHEN mt.production_year < 1990 THEN 'Old'
            WHEN mt.production_year BETWEEN 1990 AND 2000 THEN '90s'
            ELSE 'Modern'
        END AS era
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
),
keyword_data AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ',') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
company_data AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
info_data AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.companies, 'No Companies') AS companies,
    COALESCE(id.info_details, 'No Info') AS info_details,
    CASE 
        WHEN md.actor_order = 1 THEN 'Lead'
        WHEN md.actor_order <= 3 THEN 'Supporting'
        ELSE 'Minor'
    END AS role_type,
    md.era
FROM 
    movie_data md
LEFT JOIN 
    keyword_data kw ON md.movie_title = (SELECT title FROM aka_title WHERE id = kw.movie_id)
LEFT JOIN 
    company_data cd ON md.production_year = (SELECT production_year FROM aka_title WHERE id = cd.movie_id)
LEFT JOIN 
    info_data id ON md.production_year = (SELECT production_year FROM aka_title WHERE id = id.movie_id)
WHERE 
    (md.production_year IS NULL OR md.production_year >= 1980)
ORDER BY 
    md.production_year DESC, md.movie_title;
