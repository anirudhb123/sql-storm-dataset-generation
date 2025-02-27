
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        pi.info AS actor_info,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
        AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    GROUP BY 
        t.title, t.production_year, ak.name, pi.info
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_info,
    keywords
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, movie_title;
