WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year > 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    title,
    production_year,
    aka_names,
    companies,
    keyword_count,
    cast_count
FROM 
    RankedMovies
ORDER BY 
    production_year DESC, keyword_count DESC;
