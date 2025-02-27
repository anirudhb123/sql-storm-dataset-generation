WITH ActorMovies AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles,
        ARRAY_AGG(DISTINCT t.production_year) AS production_years
    FROM 
        aka_name p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        p.id, p.name
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
ActorKeywordSummary AS (
    SELECT 
        am.actor_name,
        km.keywords,
        ARRAY_LENGTH(km.keywords, 1) AS keyword_count
    FROM 
        ActorMovies am
    JOIN 
        MovieKeywords km ON am.movie_titles @> ARRAY(SELECT title FROM aka_title WHERE id = ANY(SELECT movie_id FROM cast_info WHERE person_id = am.person_id))
    WHERE 
        am.actor_name IS NOT NULL
)

SELECT 
    aks.actor_name,
    aks.keyword_count,
    string_agg(DISTINCT k.keywords, ', ') AS all_keywords
FROM 
    ActorKeywordSummary aks
JOIN 
    LATERAL unnest(aks.keywords) AS k(keyword) ON true
GROUP BY 
    aks.actor_name, aks.keyword_count
ORDER BY 
    aks.keyword_count DESC;
