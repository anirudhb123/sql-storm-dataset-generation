WITH movie_statistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        aka_title ak ON ak.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
final_statistics AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.cast_names,
        cs.total_companies,
        cs.company_names,
        ARRAY_LENGTH(ms.keywords, 1) AS keyword_count
    FROM 
        movie_statistics ms
    LEFT JOIN 
        company_statistics cs ON cs.movie_id = ms.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_cast,
    f.cast_names,
    f.total_companies,
    f.company_names,
    f.keyword_count
FROM 
    final_statistics f
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC;
