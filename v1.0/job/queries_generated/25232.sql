WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title ak_t ON t.id = ak_t.movie_id
    LEFT JOIN 
        aka_name ak ON ak_t.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        name p
    JOIN 
        cast_info ci ON ci.person_id = p.id
    GROUP BY 
        p.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
CompanyDetails AS (
    SELECT 
        c.id AS company_id,
        c.name,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON mc.company_id = c.id
    GROUP BY 
        c.id
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 3
)

SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.aliases,
    md.keywords,
    pd.person_id,
    pd.name AS actor_name,
    pd.movie_count,
    cd.company_id,
    cd.name AS company_name,
    cd.total_movies
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.title_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
JOIN 
    movie_companies mc ON md.title_id = mc.movie_id
JOIN 
    CompanyDetails cd ON mc.company_id = cd.company_id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.title;
