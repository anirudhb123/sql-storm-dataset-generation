WITH ActorTitles AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ak.name IS NOT NULL
),

FilteredTitles AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        company_type
    FROM 
        ActorTitles
    WHERE 
        title_rank <= 5
)

SELECT 
    actor_name,
    STRING_AGG(movie_title, ', ') AS titles,
    STRING_AGG(DISTINCT company_type, ', ') AS company_types,
    COUNT(*) AS movie_count
FROM 
    FilteredTitles
GROUP BY 
    actor_name
ORDER BY 
    movie_count DESC;
