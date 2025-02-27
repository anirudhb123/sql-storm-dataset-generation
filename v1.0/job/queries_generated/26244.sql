WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.kind_id) AS genre_ids,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
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
        GROUP_CONCAT(DISTINCT c.movie_id) AS movies,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        name p
    LEFT JOIN 
        cast_info c ON p.id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        p.id
),
BenchmarkResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        pd.name AS actor_name,
        pd.movie_count,
        pd.roles,
        md.companies,
        md.keywords
    FROM 
        MovieDetails md
    JOIN 
        cast_info c ON md.movie_id = c.movie_id
    JOIN 
        PersonDetails pd ON c.person_id = pd.person_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    movie_count,
    roles,
    companies,
    keywords
FROM 
    BenchmarkResults
WHERE 
    movie_count > 1
ORDER BY 
    production_year DESC, movie_count DESC;
