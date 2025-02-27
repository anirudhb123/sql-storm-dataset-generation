WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
StarCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        COUNT(cc.id) OVER (PARTITION BY c.movie_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS total_movies_by_company
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, co.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        sc.actor_name,
        ci.company_name,
        ci.company_type,
        ci.total_movies_by_company
    FROM 
        RankedMovies rm
    LEFT JOIN 
        StarCast sc ON rm.movie_id = sc.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank <= 5 AND 
        (ci.total_movies_by_company IS NULL OR ci.total_movies_by_company > 1)
)

SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.company_name,
    f.company_type
FROM 
    FilteredMovies f
WHERE 
    f.actor_name IS NOT NULL
ORDER BY 
    f.production_year DESC, f.title ASC;
