
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ac.person_id,
        ak.name,
        COUNT(DISTINCT ac.movie_id) AS total_movies,
        MIN(ac.nr_order) AS first_movie_order
    FROM 
        cast_info ac
    JOIN 
        aka_name ak ON ac.person_id = ak.person_id 
    JOIN 
        RankedMovies rm ON ac.movie_id = rm.movie_id
    WHERE 
        rm.rank_per_year <= 3 
    GROUP BY 
        ac.person_id, ak.name
),
CompanyDetail AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS num_companies
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
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    ta.total_movies,
    ca.company_name,
    ca.company_type,
    ca.num_companies,
    COALESCE(ta.first_movie_order, -1) AS first_movie_order
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id = ta.person_id
LEFT JOIN 
    CompanyDetail ca ON rm.movie_id = ca.movie_id
ORDER BY 
    rm.production_year DESC, ta.total_movies DESC NULLS LAST;
