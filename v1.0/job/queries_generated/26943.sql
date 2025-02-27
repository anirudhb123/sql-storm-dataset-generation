WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
CastInfo AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.actor_name,
        ci.role_type,
        co.company_name,
        co.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastInfo ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        CompanyInfo co ON rm.movie_id = co.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name || ' (' || md.role_type || ')', ', ') AS actors,
    STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', ', ') AS companies
FROM 
    MovieDetails md
WHERE 
    md.production_year IS NOT NULL
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
