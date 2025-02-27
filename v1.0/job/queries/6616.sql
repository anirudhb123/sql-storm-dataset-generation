WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        AVG(CAST(ci.nr_order AS FLOAT)) AS avg_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighRatedTitles AS (
    SELECT 
        m.movie_id, 
        m.title,
        m.production_year
    FROM 
        RankedMovies m
    WHERE 
        m.avg_order > 2.5
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    ht.title,
    ht.production_year,
    fc.company_name,
    fc.company_type,
    rm.actor_names
FROM 
    HighRatedTitles ht
LEFT JOIN 
    FilteredCompanies fc ON ht.movie_id = fc.movie_id
LEFT JOIN 
    RankedMovies rm ON ht.movie_id = rm.movie_id
ORDER BY 
    ht.production_year DESC, 
    ht.title;
