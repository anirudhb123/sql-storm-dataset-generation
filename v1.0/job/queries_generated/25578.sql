WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank_year,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY a.title) AS rank_keyword
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),

FilteredCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS person_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.nr_order <= 5
),

FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keyword,
        fc.person_name,
        fc.role_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast fc ON rm.production_year = fc.movie_id
    WHERE 
        rm.rank_year = 1 OR rm.rank_keyword = 1
)

SELECT 
    title,
    production_year,
    keyword,
    person_name,
    role_name
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;
