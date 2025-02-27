WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
company_aggregates AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
high_profile_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.cast_count,
        ca.company_count,
        ca.companies
    FROM 
        movie_details md
    JOIN 
        company_aggregates ca ON md.movie_id = ca.movie_id
    WHERE 
        md.cast_count > 5 AND ca.company_count > 2
)
SELECT 
    hpm.title,
    hpm.production_year,
    hpm.actors,
    hpm.company_count,
    hpm.companies,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_keyword mk 
     WHERE 
        mk.movie_id = hpm.movie_id
    ) AS keyword_count
FROM 
    high_profile_movies hpm
ORDER BY 
    hpm.production_year DESC, hpm.company_count ASC;
