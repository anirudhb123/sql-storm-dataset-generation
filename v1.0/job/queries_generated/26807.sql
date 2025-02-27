WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
KeywordStats AS (
    SELECT 
        movie_id,
        COUNT(keyword) AS keyword_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.roles,
    md.companies,
    md.cast_count,
    ks.keyword_count
FROM 
    MovieDetails md
JOIN 
    KeywordStats ks ON md.movie_id = ks.movie_id
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC, 
    ks.keyword_count DESC;
