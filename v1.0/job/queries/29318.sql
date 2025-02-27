
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT CONCAT(rc.role, ' as ', p.name), ', ') AS cast_details
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        role_type rc ON ci.role_id = rc.id
    LEFT JOIN 
        name p ON ak.person_id = p.imdb_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies,
    md.cast_details
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC;
