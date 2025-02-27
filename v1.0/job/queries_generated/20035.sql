WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMovieData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.actor_name, 'Unknown Actor') AS main_actor,
        COALESCE(ca.company_name, 'Independent') AS producing_company,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        rm.total_movies,
        rn
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id AND ar.nr_order = 1
    LEFT JOIN 
        CompanyMovies ca ON rm.movie_id = ca.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    main_actor,
    producing_company,
    keywords,
    (SELECT COUNT(DISTINCT category_id) 
     FROM movie_info mi 
     WHERE mi.movie_id = fmd.movie_id AND mi.info LIKE '%Oscar%') AS oscar_nominations,
    (CASE 
        WHEN total_movies > 1 THEN 'Multi-Movie Year'
        ELSE 'Single Movie Year'
     END) AS year_category
FROM 
    FinalMovieData fmd
WHERE 
    fmd.production_year BETWEEN 1990 AND 2020
ORDER BY 
    fmd.production_year DESC, title ASC
LIMIT 100;
