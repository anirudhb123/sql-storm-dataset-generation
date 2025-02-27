WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
), 

PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(ci.id) AS movies_acted_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    GROUP BY 
        p.id, p.name
    HAVING 
        COUNT(ci.id) > 5
),

CompanyDetails AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        COUNT(mc.movie_id) AS produced_movies_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.id, c.name
    HAVING 
        COUNT(mc.movie_id) > 10
)

SELECT 
    md.title,
    md.production_year,
    pd.name AS lead_actor,
    cd.company_name,
    md.movie_keyword,
    md.cast_count,
    pd.movies_acted_count,
    cd.produced_movies_count
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
JOIN 
    CompanyDetails cd ON mc.company_id = cd.company_id
WHERE 
    pd.movies_acted_count > 10  
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;