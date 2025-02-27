WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS movie_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 1990 AND 2000
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
CompanyDetails AS (
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
    WHERE 
        cn.country_code = 'USA'
),
TitleKeywords AS (
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
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ar.actor_name) AS total_actors,
        COUNT(DISTINCT cd.company_name) AS total_companies,
        COALESCE(tk.keywords, 'No Keywords') AS keywords,
        rm.movie_count,
        CASE 
            WHEN rm.movie_count > 5 THEN 'Popular'
            WHEN rm.movie_count < 3 THEN 'Rarely Exists'
            ELSE 'Moderately Available'
        END AS movie_availability
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        TitleKeywords tk ON rm.movie_id = tk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, tk.keywords, rm.movie_count
)
SELECT * 
FROM FinalResults
WHERE 
    (total_actors = 0 OR total_companies = 0) 
    AND movie_availability = 'Rarely Exists' 
ORDER BY 
    production_year DESC, total_actors DESC;