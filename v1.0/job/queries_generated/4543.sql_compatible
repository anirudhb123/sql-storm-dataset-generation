
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

ActorMovieCount AS (
    SELECT 
        ak.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id
), 

CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 

KeywordMovies AS (
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
    tm.title, 
    tm.production_year, 
    ac.movie_count, 
    cm.company_name, 
    cm.company_type, 
    km.keywords
FROM 
    RankedMovies tm
LEFT JOIN 
    ActorMovieCount ac ON tm.movie_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci
        WHERE 
            ci.person_role_id = (
                SELECT 
                    id 
                FROM 
                    role_type 
                WHERE 
                    role = 'lead'
            )
    )
LEFT JOIN 
    CompanyMovies cm ON tm.movie_id = cm.movie_id
LEFT JOIN 
    KeywordMovies km ON tm.movie_id = km.movie_id
WHERE 
    tm.rank = 1
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
