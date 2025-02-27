WITH movie_info_aggregates AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT c.company_name, ', ') AS production_companies
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
cast_info_aggregates AS (
    SELECT 
        ct.id AS title_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        title ct
    JOIN 
        complete_cast cc ON ct.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ct.id
)
SELECT 
    mia.movie_title,
    mia.production_year,
    mia.keyword_count,
    mia.production_companies,
    cia.cast_count,
    cia.cast_names
FROM 
    movie_info_aggregates mia
LEFT JOIN 
    cast_info_aggregates cia ON mia.movie_title = cia.title_id
WHERE 
    mia.production_year >= 2000
ORDER BY 
    mia.production_year DESC, mia.keyword_count DESC;

