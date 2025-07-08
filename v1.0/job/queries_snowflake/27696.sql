
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_within_year
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword ILIKE '%action%'  
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        p.gender,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        name p ON ak.person_id = p.imdb_id
    WHERE 
        p.gender = 'M'  
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
),
FinalBenchmarking AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ad.actor_name,
        cd.company_name,
        cd.company_type,
        rm.rank_within_year,
        ad.actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    title,
    production_year,
    COUNT(DISTINCT actor_name) AS total_actors,
    LISTAGG(DISTINCT company_name || ' (' || company_type || ')', ', ') WITHIN GROUP (ORDER BY company_name) AS companies_involved,
    MIN(rank_within_year) AS min_rank_within_year,
    MAX(actor_rank) AS max_actor_rank
FROM 
    FinalBenchmarking
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, title;
