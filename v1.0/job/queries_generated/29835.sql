WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieIndustry AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(*) DESC) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
Result AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        mi.company_name,
        mi.company_type,
        ks.keyword,
        ks.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id AND ar.actor_rank <= 5
    LEFT JOIN 
        MovieIndustry mi ON rm.movie_id = mi.movie_id AND mi.company_rank = 1
    LEFT JOIN 
        KeywordStats ks ON rm.movie_id = ks.movie_id AND ks.keyword_rank <= 3
)
SELECT 
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' as ' || role_name, ', ') AS actors,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
    STRING_AGG(DISTINCT keyword || ' (' || keyword_count || ')', ', ') AS keywords
FROM 
    Result
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, movie_id;
