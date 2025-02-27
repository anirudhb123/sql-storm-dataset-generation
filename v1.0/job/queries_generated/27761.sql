WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank_by_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
CompanyMovieDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        co.country_code,
        cm.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type cm ON mc.company_type_id = cm.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    fa.name AS actor_name,
    cmd.company_name,
    cmd.country_code,
    cmd.company_type,
    mk.keyword AS movie_keyword
FROM 
    RankedMovies rm
JOIN 
    FilteredActors fa ON rm.movie_id = fa.movie_id
JOIN 
    CompanyMovieDetails cmd ON rm.movie_id = cmd.movie_id
JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_year <= 5
    AND fa.actor_rank <= 10
ORDER BY 
    rm.production_year, 
    rm.title,
    fa.nr_order;
