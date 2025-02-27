WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
average_cast AS (
    SELECT 
        AVG(cast_count) AS avg_cast_size
    FROM 
        movie_details
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies,
    md.cast_count,
    avg_cast.avg_cast_size
FROM 
    movie_details md
CROSS JOIN 
    average_cast avg_cast
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 100;
