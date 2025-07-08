
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS title_count
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CompanyWithMovies AS (
    SELECT 
        c.name AS company_name,
        mc.movie_id,
        COUNT(mc.id) AS company_movie_count
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name, mc.movie_id
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
ActorRoles AS (
    SELECT 
        a.name, 
        ci.movie_id, 
        ci.role_id,
        ct.kind AS role_type
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year
    FROM 
        RankedMovies m
    WHERE 
        m.title_rank < 5 AND
        m.title_count > 1
),
FinalReport AS (
    SELECT 
        f.title AS movie_title,
        f.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        LISTAGG(DISTINCT c.company_name, ', ') WITHIN GROUP (ORDER BY c.company_name) AS companies
    FROM 
        FilteredMovies f
    LEFT JOIN 
        ActorRoles ak ON f.movie_id = ak.movie_id
    LEFT JOIN 
        DistinctKeywords kw ON f.movie_id = kw.movie_id
    LEFT JOIN 
        CompanyWithMovies c ON f.movie_id = c.movie_id
    GROUP BY 
        f.movie_id, f.title, f.production_year
    ORDER BY 
        f.production_year DESC
)
SELECT 
    FinalReport.*,
    CASE 
        WHEN production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(production_year AS VARCHAR) 
    END AS display_year,
    CASE 
        WHEN actors IS NULL THEN 'No Actors'
        ELSE actors 
    END AS actor_display,
    COALESCE(companies, 'No Companies') AS company_display
FROM 
    FinalReport
WHERE 
    movie_title IS NOT NULL 
    AND production_year >= 2000
    AND (actors IS NOT NULL OR companies IS NOT NULL)
ORDER BY 
    movie_title;
