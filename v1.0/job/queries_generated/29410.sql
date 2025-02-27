WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' (', r.role, ')') ORDER BY a.name SEPARATOR ', ') AS cast_list,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        COALESCE(i.info, 'No additional info') AS additional_info
    FROM
        MovieDetails md
    LEFT JOIN 
        movie_info i ON md.movie_id = i.movie_id
)
SELECT 
    mid.movie_title,
    mid.production_year,
    mid.cast_list,
    mid.keywords,
    mid.companies,
    mid.additional_info
FROM 
    MovieInfo mid
WHERE 
    mid.production_year >= 2000
ORDER BY 
    mid.production_year DESC, mid.movie_title;

