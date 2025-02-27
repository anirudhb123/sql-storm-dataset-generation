WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
EmployeeStats AS (
    SELECT 
        p.person_id,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS known_as,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        p.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name) AS companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name END) AS distributor_name,
        MAX(CASE WHEN ct.kind = 'Producer' THEN cn.name END) AS producer_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieRankings AS (
    SELECT 
        title_id,
        title,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(rn) DESC) AS rank_with_cnt
    FROM 
        RecursiveMovieTitles rt
    LEFT JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    mt.title,
    mt.production_year,
    cs.companies,
    cs.distributor_name,
    cs.producer_name,
    es.known_as,
    es.movie_count,
    es.avg_order,
    COALESCE(mr.rank_with_cnt, 'N/A') AS movie_rank,
    CASE 
        WHEN mr.rank_with_cnt IS NOT NULL AND mr.rank_with_cnt < 10 THEN 'Top 10 Movie'
        ELSE 'Other'
    END AS movie_category
FROM 
    MovieRankings mr
LEFT JOIN 
    CompanyDetails cs ON mr.title_id = cs.movie_id
LEFT JOIN 
    EmployeeStats es ON es.movie_count > 0
WHERE 
    mr.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mr.production_year DESC,
    movie_rank;
