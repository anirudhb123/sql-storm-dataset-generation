
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title AS at
    LEFT JOIN 
        cast_info AS ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
SelectedMovies AS (
    SELECT 
        movie_title,
        production_year,
        num_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
MovieKeywords AS (
    SELECT 
        at.title,
        k.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.num_cast,
    LISTAGG(mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords,
    COALESCE(ai.name, 'Unknown') AS actor_name,
    SUM(CASE 
            WHEN ai.id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS featured_actors
FROM 
    SelectedMovies sm
LEFT JOIN 
    MovieKeywords mk ON sm.movie_title = mk.title
LEFT JOIN 
    cast_info ci ON sm.movie_title = (SELECT at.title FROM aka_title at WHERE at.id = ci.movie_id)
LEFT JOIN 
    aka_name ai ON ci.person_id = ai.person_id
GROUP BY 
    sm.movie_title, sm.production_year, sm.num_cast, ai.name
ORDER BY 
    sm.production_year DESC, sm.num_cast DESC;
