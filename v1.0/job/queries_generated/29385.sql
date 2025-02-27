WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT CONCAT(a.first_name, ' ', a.last_name)) AS cast,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id 
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id 
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
BenchmarkResults AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year,
        md.keywords,
        md.companies,
        md.cast,
        md.info_count,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic Era'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
            ELSE 'Recent Era' 
        END AS era
    FROM 
        MovieDetails md
)
SELECT 
    era,
    COUNT(movie_id) AS movie_count,
    AVG(info_count) AS average_info_count,
    ARRAY_AGG(DISTINCT title) AS titles,
    UNNEST(keywords) AS keyword
FROM 
    BenchmarkResults
GROUP BY 
    era
ORDER BY 
    movie_count DESC, average_info_count DESC;
