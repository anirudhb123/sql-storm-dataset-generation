WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
NameInfo AS (
    SELECT 
        n.name,
        n.gender,
        COUNT(ci.id) AS cast_count
    FROM 
        name n
    JOIN 
        cast_info ci ON ci.person_id = n.imdb_id
    WHERE 
        n.gender = 'F' 
    GROUP BY 
        n.name, n.gender
),
MovieCompanies AS (
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
    rm.title,
    rm.production_year,
    rm.keyword,
    ni.name AS actress_name,
    ni.cast_count,
    mc.company_name,
    mc.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    NameInfo ni ON ni.cast_count > 0
JOIN 
    MovieCompanies mc ON mc.movie_id = rm.id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, 
    ni.cast_count DESC, 
    rm.title;
