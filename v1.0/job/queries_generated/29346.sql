WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
),

KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    km.keywords,
    cm.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_title = km.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_title = cm.movie_id
WHERE 
    rm.actor_rank <= 3 -- Considering top 3 actors for each movie
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
