WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.actor_name,
    ci.company_name,
    ci.company_type,
    ci.total_movies,
    (SELECT COUNT(*) FROM MovieKeyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id AND mc.actor_rank <= 3
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year, mc.actor_rank DESC, ci.total_movies DESC NULLS LAST;
