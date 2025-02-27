WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
KeywordSummary AS (
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
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.movie_titles,
    k.keywords,
    c.company_names,
    c.company_types
FROM 
    ActorMovies a
LEFT JOIN 
    KeywordSummary k ON a.movie_titles LIKE '%' || k.movie_id || '%'
LEFT JOIN 
    CompanyDetails c ON a.movie_titles LIKE '%' || c.movie_id || '%'
ORDER BY 
    a.movie_count DESC;
