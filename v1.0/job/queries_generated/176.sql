WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank_by_year
    FROM 
        aka_title a
    WHERE 
        a.production_year < 2000
),
CharNamesWithCounts AS (
    SELECT 
        c.id AS char_id,
        c.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        char_name c
    LEFT JOIN 
        cast_info ci ON ci.person_id = c.imdb_id
    GROUP BY 
        c.id, c.name
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(cn.movie_count, 0) AS character_count,
    mci.company_name,
    mci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordInfo k ON rm.movie_id = k.movie_id
LEFT JOIN 
    CharNamesWithCounts cn ON cn.movie_count > 1
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    rn.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
