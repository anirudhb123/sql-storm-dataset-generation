WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name AS person_name,
        GROUP_CONCAT(DISTINCT r.role) AS roles,
        COUNT(DISTINCT ci.movie_id) AS movies_appeared_in
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.person_id
),
BenchmarkResults AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        pd.person_name,
        pd.roles,
        pd.movies_appeared_in,
        LENGTH(md.movie_title) AS title_length,
        LENGTH(pd.person_name) AS person_name_length
    FROM 
        MovieDetails md
    JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        PersonDetails pd ON a.person_id = pd.person_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    person_name,
    roles,
    movies_appeared_in,
    title_length,
    person_name_length
FROM 
    BenchmarkResults
WHERE 
    movies_appeared_in > 3
ORDER BY 
    production_year DESC, 
    title_length DESC;
