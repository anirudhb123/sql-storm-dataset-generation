WITH MovieDetails AS (
    SELECT 
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        a.name AS ActorName,
        c.kind AS Role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS ActorRank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        t.title AS MovieTitle,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS KeywordRank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.MovieTitle,
    md.ProductionYear,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS Keywords,
    COUNT(DISTINCT md.ActorName) AS ActorCount,
    MAX(md.ActorRank) AS MaxActorRank
FROM 
    MovieDetails md
LEFT JOIN 
    MovieKeywords mk ON md.MovieTitle = mk.MovieTitle AND mk.KeywordRank <= 3
WHERE 
    md.ProductionYear BETWEEN 2000 AND 2020
GROUP BY 
    md.MovieTitle, md.ProductionYear
HAVING 
    COUNT(DISTINCT md.ActorName) > 5
ORDER BY 
    md.ProductionYear DESC, ActorCount DESC;
