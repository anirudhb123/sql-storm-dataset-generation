WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aka_names,
    md.keywords,
    COALESCE(md.companies, 'No Companies') AS companies,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast' 
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
