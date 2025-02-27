WITH RecursiveCTE AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(t.title, 'Untitled') AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_sequence
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year >= 2000
),
AggregateCTE AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS total_actors,
        STRING_AGG(DISTINCT actor_name, ', ') AS actor_list
    FROM 
        RecursiveCTE
    GROUP BY 
        movie_id
),
MovieCompanyDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        cn.country_code = 'USA'
),
FinalResult AS (
    SELECT 
        a.movie_id,
        a.actor_list,
        a.total_actors,
        mcd.company_name,
        mcd.company_type,
        t.production_year
    FROM 
        AggregateCTE a
    JOIN 
        MovieCompanyDetails mcd ON a.movie_id = mcd.movie_id
    JOIN 
        aka_title t ON a.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
        AND a.total_actors > 5
)

SELECT 
    fr.movie_id,
    fr.actor_list,
    fr.total_actors,
    fr.company_name,
    fr.company_type,
    fr.production_year,
    CASE 
        WHEN fr.production_year < 2010 THEN 'Classic'
        WHEN fr.production_year BETWEEN 2010 AND 2015 THEN 'Recent'
        ELSE 'Modern'
    END AS era,
    CASE 
        WHEN fr.company_type LIKE '%Studio%' THEN 'Production'
        ELSE 'Distribution'
    END AS company_role
FROM 
    FinalResult fr
ORDER BY 
    fr.production_year DESC;
