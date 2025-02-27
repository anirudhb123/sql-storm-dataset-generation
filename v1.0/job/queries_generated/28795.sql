WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT t.movie_title, ', ') AS movies,
        COUNT(t.movie_title) AS movie_count
    FROM 
        aka_name a
    JOIN 
        RankedTitles t ON a.name = t.actor_name
    WHERE 
        t.ranking <= 3 -- Get top 3 movies
    GROUP BY 
        a.id, a.name
),
CompanyDetails AS (
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
)
SELECT 
    ai.actor_name,
    ai.movies,
    ai.movie_count,
    cd.company_name,
    cd.company_type,
    mk.keywords
FROM 
    ActorInfo ai
LEFT JOIN 
    complete_cast cc ON ai.actor_id = cc.subject_id
LEFT JOIN 
    CompanyDetails cd ON cc.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON cc.movie_id = mk.movie_id
ORDER BY 
    ai.actor_name;
