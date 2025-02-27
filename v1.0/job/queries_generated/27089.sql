WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS number_of_actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_companies,
        rm.companies,
        STRING_AGG(DISTINCT CONCAT(pr.role, ' (', pr.number_of_actors, ')'), ', ') AS role_distribution
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.movie_id = pr.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.total_companies, rm.companies
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_companies,
    ms.companies,
    ms.role_distribution
FROM 
    MovieStats ms
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, 
    ms.total_companies DESC;
