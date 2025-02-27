WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.companies,
    rm.keywords,
    cd.actor_names,
    cd.roles
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;
