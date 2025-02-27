WITH MovieTitleKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
ActorWithMovies AS (
    SELECT 
        a.name AS actor_name,
        STRING_AGG(DISTINCT at.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        a.name
),
MovieCompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CompleteMovieInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.keywords,
        ac.actor_name,
        mc.company_name,
        mc.company_type
    FROM 
        MovieTitleKeywords mt
    LEFT JOIN 
        ActorWithMovies ac ON TRUE -- Cross join to get all actors with all movies
    LEFT JOIN 
        MovieCompanyInfo mc ON mt.movie_id = mc.movie_id
)
SELECT 
    title,
    actor_name,
    keywords,
    company_name,
    company_type
FROM 
    CompleteMovieInfo
WHERE 
    (keywords IS NOT NULL AND keywords <> '')
    AND (company_name IS NOT NULL OR company_type IS NOT NULL)
ORDER BY 
    title, actor_name;
