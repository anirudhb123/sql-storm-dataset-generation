WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count,
        FIRST_VALUE(a.name) OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS first_actor
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithKeyword AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalBenchmark AS (
    SELECT 
        rm.title,
        rm.production_year,
        cd.actor_count,
        cd.first_actor,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
        COALESCE(cd.actor_role, 'No Role') AS actor_role,
        cp.company_name,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, actor_count DESC) AS ranking
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MoviesWithKeyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyDetails cp ON rm.movie_id = cp.movie_id
)
SELECT 
    title,
    production_year,
    actor_count,
    first_actor,
    movie_keywords,
    actor_role,
    company_name,
    ranking
FROM 
    FinalBenchmark
WHERE 
    (actor_count > 1 OR production_year < 2000) 
    AND (company_name IS NOT NULL OR movie_keywords IS NOT NULL)
ORDER BY 
    ranking ASC;
