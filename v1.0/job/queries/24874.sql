WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%adventure%'
        AND t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id, 
        a.name, 
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY ci.nr_order) AS actor_movie_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL AND a.name != ''
),
CompanyStats AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.id) AS company_count,
        SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        am.person_id, 
        am.name AS actor_name,
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.distributor_count, 0) AS distributor_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.title) AS movie_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.company_count,
    md.distributor_count,
    CASE 
        WHEN md.movie_order IS NOT NULL 
        THEN CONCAT('Rank ', md.movie_order)
        ELSE 'No Actors'
    END AS rank_info
FROM 
    MovieDetails md
WHERE 
    md.company_count >= 2
    OR md.distributor_count >= 1
    AND md.production_year = (
        SELECT MAX(production_year) 
        FROM RankedMovies
    )
ORDER BY 
    md.production_year DESC, 
    md.title;
