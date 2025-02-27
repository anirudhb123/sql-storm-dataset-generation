WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS num_actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
CompanyWorks AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT cm.company_id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_list
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    GROUP BY 
        m.movie_id
),
RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(CAST(mr.num_actors AS INTEGER), 0) AS num_actors,
        COALESCE(cw.num_companies, 0) AS num_companies,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, num_actors DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        MovieRoles mr ON t.id = mr.movie_id
    LEFT JOIN 
        CompanyWorks cw ON t.id = cw.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND (t.production_year >= 2000 OR t.production_year IS NULL)
        AND EXISTS (
            SELECT 1 
            FROM movie_keyword mk
            WHERE mk.movie_id = t.id
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Drama', 'Thriller'))
        )
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    rm.num_companies,
    rm.rank,
    CASE 
        WHEN rm.num_companies = 0 THEN 'No Companies Available'
        ELSE 'Produced by: ' || rm.companies_list
    END AS production_info,
    CASE 
        WHEN rm.num_actors > 5 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_type
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
