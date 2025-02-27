WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names,
        companies_involved,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_by_cast
    FROM 
        RankedMovies
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_cast,
    f.aka_names,
    f.companies_involved,
    f.rank_by_cast
FROM 
    FilteredMovies f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, f.rank_by_cast ASC
LIMIT 20;