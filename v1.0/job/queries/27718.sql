WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.name AS company_name,
        c.country_code,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, c.name, c.country_code, k.keyword
),
RoleStatistics AS (
    SELECT 
        role_id,
        COUNT(DISTINCT movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT ni.name) AS role_names
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        name ni ON ci.person_id = ni.imdb_id
    GROUP BY 
        role_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.kind_id,
        md.company_name,
        r.role_names,
        rg.movie_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        RoleStatistics r ON r.role_id = (SELECT id FROM role_type LIMIT 1)  
    LEFT JOIN 
        (SELECT role_id, COUNT(*) AS movie_count FROM cast_info GROUP BY role_id) rg ON rg.role_id = r.role_id
)
SELECT 
    movie_title,
    production_year,
    kind_id,
    company_name,
    role_names,
    movie_count
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, movie_title;