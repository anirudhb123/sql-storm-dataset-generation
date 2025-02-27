WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS alternative_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
BenchmarkResult AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.alternative_names,
        md.companies,
        md.keyword_count,
        SUM(CASE WHEN mr.role IS NOT NULL THEN mr.actor_count ELSE 0 END) AS total_actors
    FROM 
        MovieData md
    LEFT JOIN 
        MovieRoles mr ON md.movie_id = mr.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.alternative_names, md.companies, md.keyword_count
)
SELECT 
    movie_id,
    title,
    production_year,
    alternative_names,
    companies,
    keyword_count,
    total_actors
FROM 
    BenchmarkResult
ORDER BY 
    production_year DESC, title;
