WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),

RankedMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.cast_names,
        md.companies,
        md.roles,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY COUNT(DISTINCT md.cast_names) DESC) AS movie_rank
    FROM 
        MovieDetails md
    WHERE 
        md.movie_keyword IS NOT NULL
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year, md.movie_keyword, md.cast_names, md.companies, md.roles
)

SELECT 
    rm.movie_rank,
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.cast_names,
    rm.companies,
    rm.roles
FROM 
    RankedMovies rm
WHERE 
    rm.movie_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_rank;
