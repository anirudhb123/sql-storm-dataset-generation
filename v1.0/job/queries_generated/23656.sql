WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(b.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.movie_id = b.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
ActorInfo AS (
    SELECT 
        c.person_id,
        n.name AS actor_name,
        COUNT(cc.id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies_list
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    LEFT JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    WHERE 
        m.rank <= 5
    GROUP BY 
        c.person_id, n.name
),
CompanyProduction AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FilteredInfo AS (
    SELECT 
        a.actor_name,
        a.movie_count,
        cp.company_count,
        cp.companies
    FROM 
        ActorInfo a
    LEFT JOIN 
        CompanyProduction cp ON a.movie_count > 3
    WHERE 
        a.actor_name IS NOT NULL 
        AND (a.movie_count > 0 OR cp.company_count IS NOT NULL)
    ORDER BY 
        a.movie_count DESC
)
SELECT 
    actor_name,
    movie_count,
    COALESCE(company_count, 0) AS company_count,
    COALESCE(companies, 'No companies listed') AS companies
FROM 
    FilteredInfo
WHERE 
    movie_count >= (SELECT AVG(movie_count) FROM ActorInfo)
    AND company_count < 5
LIMIT 15 OFFSET 5;
