WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.kind AS company_type,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, k.keyword, c.kind
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year, 
        keyword, 
        company_type, 
        cast_count, 
        aka_names
    FROM 
        MovieDetails
    WHERE 
        cast_count > 5
)
SELECT 
    title, 
    production_year, 
    keyword, 
    company_type, 
    cast_count, 
    aka_names
FROM 
    HighCastMovies
ORDER BY 
    production_year DESC, 
    cast_count DESC;
