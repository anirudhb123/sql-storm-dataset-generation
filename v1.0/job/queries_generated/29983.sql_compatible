
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        aka_name AS ak ON ak.person_id = t.id
    JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    JOIN 
        company_name AS cn ON cn.id = mc.company_id
    JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    JOIN 
        keyword AS k ON k.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON rt.id = ci.role_id
    GROUP BY 
        ci.movie_id
),
DetailedBenchmark AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.aliases,
        rc.actor_count,
        rc.roles,
        md.company_names,
        md.keywords
    FROM 
        MovieDetails AS md
    LEFT JOIN 
        RoleCounts AS rc ON rc.movie_id = md.movie_id
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    aliases,
    actor_count,
    roles,
    company_names,
    keywords
FROM 
    DetailedBenchmark
ORDER BY 
    production_year DESC, 
    actor_count DESC;
