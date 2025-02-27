WITH MovieSummary AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count,
        COUNT(DISTINCT ci.role_id) AS roles_count
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id
),
FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actors,
        keywords,
        company_count,
        roles_count
    FROM 
        MovieSummary
    WHERE 
        production_year >= 2000 AND 
        company_count > 1 AND 
        roles_count > 3
)
SELECT 
    movie_title,
    actors,
    keywords,
    production_year,
    company_count
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, 
    company_count DESC;
