WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        COUNT(DISTINCT i.info_type_id) AS info_types_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
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
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    keywords,
    company_names,
    cast_count,
    info_types_count
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, cast_count DESC;
