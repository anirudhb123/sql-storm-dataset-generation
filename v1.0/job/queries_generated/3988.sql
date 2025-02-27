WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
), MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
), ActorMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keywords,
        rank
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieKeywords mk ON rt.movie_title = mk.movie_id
)
SELECT 
    am.actor_name,
    am.movie_title,
    COALESCE(am.keywords, 'No Keywords') AS keywords,
    am.production_year,
    CASE 
        WHEN am.rank <= 3 THEN 'Top 3 Recent Movies'
        ELSE 'Other Movies'
    END AS classification
FROM 
    ActorMovies am
WHERE 
    am.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    am.actor_name, am.production_year DESC;
