
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        rk.rank AS actor_rank,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title AS at
    LEFT JOIN 
        cast_info AS ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = at.id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        (SELECT 
            movie_id,
            RANK() OVER (PARTITION BY movie_id ORDER BY COUNT(*) DESC) AS rank
         FROM 
            cast_info 
         GROUP BY 
            movie_id) AS rk ON rk.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, rk.rank
    HAVING 
        COUNT(DISTINCT ak.person_id) > 3 
        AND SUM(CASE WHEN ak.name ILIKE '%Smith%' THEN 1 ELSE 0 END) > 0
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_rank,
    rm.actor_names,
    cd.company_names,
    CASE 
        WHEN cd.company_names IS NULL THEN 'Unknown Companies'
        ELSE cd.company_names
    END AS finalized_company_names,
    COALESCE(rm.company_count, 0) AS total_companies,
    CASE 
        WHEN rm.actor_rank IS NULL THEN 'No Rank'
        ELSE CAST(rm.actor_rank AS TEXT)
    END AS actor_rank_status
FROM 
    RankedMovies AS rm
FULL OUTER JOIN 
    CompanyDetails AS cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.production_year DESC NULLS LAST, 
    rm.title ASC;
