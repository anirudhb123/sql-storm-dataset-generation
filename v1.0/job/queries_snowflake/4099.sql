
WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
),
RatedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        cd.company_count,
        md.actor_names,
        COALESCE(cd.company_names, 'No companies') AS company_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.company_count,
    rm.actor_names,
    rm.company_names,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY rm.actor_count DESC) AS rank_by_actor_count
FROM 
    RatedMovies rm
WHERE 
    rm.actor_count > 0
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
