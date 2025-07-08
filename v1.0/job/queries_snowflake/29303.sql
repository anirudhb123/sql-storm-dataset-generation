
WITH ActorTitles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
),
FilteredTitles AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        ActorTitles
    WHERE 
        rank <= 3  
),
MovieKeywordInfo AS (
    SELECT 
        m.title AS movie_title,
        k.keyword,
        mk.id AS movie_keyword_id
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
AggregatedKeywords AS (
    SELECT 
        movie_title,
        LISTAGG(keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
    FROM 
        MovieKeywordInfo
    GROUP BY 
        movie_title
)
SELECT 
    ft.actor_name,
    ft.movie_title,
    ft.production_year,
    ak.keywords
FROM 
    FilteredTitles ft
LEFT JOIN 
    AggregatedKeywords ak ON ft.movie_title = ak.movie_title
ORDER BY 
    ft.actor_name, ft.production_year DESC;
