WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
    HAVING 
        COUNT(c.person_id) > 5
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mci.companies, 'No companies listed') AS companies
FROM 
    RankedMovies r
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON r.movie_id = mci.movie_id
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
