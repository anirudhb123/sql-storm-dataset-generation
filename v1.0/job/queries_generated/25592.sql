WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT r.role, ', ') AS cast_roles,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_per_year
    FROM
        MovieData md
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    companies,
    cast_roles,
    total_cast,
    rank_per_year
FROM 
    RankedMovies
WHERE 
    rank_per_year = 1
ORDER BY 
    production_year DESC;
