
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank,
        km.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON mk.movie_id = at.id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        ak.name, at.title, at.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ',') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    ai.actor_name,
    ai.role_count,
    cd.company_names,
    cd.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    ActorInfo ai ON tm.title = ai.title AND tm.production_year = ai.production_year
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = (
        SELECT 
            mc.movie_id 
        FROM 
            movie_companies mc 
        JOIN 
            aka_title at ON mc.movie_id = at.id 
        WHERE 
            at.title = tm.title AND at.production_year = tm.production_year
        LIMIT 1
    )
WHERE 
    cd.company_names IS NOT NULL
    OR ai.role_count = 0
ORDER BY 
    tm.production_year DESC, tm.title;
