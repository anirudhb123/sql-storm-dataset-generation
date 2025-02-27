WITH ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        STRING_AGG(t.title, ', ') AS all_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.name, t.production_year, t.kind_id
), 
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
ActorKeywordCounts AS (
    SELECT 
        a.actor_name,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM 
        ActorTitles a 
    JOIN 
        TitleKeywords k ON a.movie_title = k.title
    GROUP BY 
        a.actor_name
)
SELECT 
    ak.actor_name,
    ak.keyword_count,
    ak.all_keywords,
    tt.all_titles,
    tt.production_year
FROM 
    ActorKeywordCounts ak
JOIN 
    ActorTitles tt ON ak.actor_name = tt.actor_name
WHERE 
    ak.keyword_count > 0
ORDER BY 
    ak.keyword_count DESC, 
    tt.production_year DESC;
