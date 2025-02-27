WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mcin.company_id,
        cn.name AS company_name,
        ctype.kind AS company_type,
        mk.keyword AS movie_keyword
    FROM 
        RankedMovies rm
    JOIN 
        movie_companies mcin ON rm.movie_id = mcin.movie_id
    JOIN 
        company_name cn ON mcin.company_id = cn.id
    JOIN 
        company_type ctype ON mcin.company_type_id = ctype.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
WHERE 
    md.production_year > 2000
GROUP BY 
    md.title, md.production_year
ORDER BY 
    total_cast DESC, md.production_year DESC;
