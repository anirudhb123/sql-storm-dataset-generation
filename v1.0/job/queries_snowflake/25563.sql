
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),

ActorsInMovies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),

CompanyMovieInfo AS (
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    LISTAGG(DISTINCT ai.actor_name, ', ') WITHIN GROUP (ORDER BY ai.actor_name) AS actors,
    LISTAGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', '; ') WITHIN GROUP (ORDER BY cm.company_name) AS production_companies,
    LISTAGG(DISTINCT rm.keyword, ', ') WITHIN GROUP (ORDER BY rm.keyword) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies ai ON rm.movie_id = ai.movie_id
LEFT JOIN 
    CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC;
