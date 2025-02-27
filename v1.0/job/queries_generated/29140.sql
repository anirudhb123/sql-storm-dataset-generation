WITH ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id AS actor_id,
        at.title AS movie_title,
        at.production_year,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        ak.name NOT LIKE '%[!a-zA-Z]%'
    GROUP BY 
        ak.name, ak.person_id, at.title, at.production_year
),
DirectorMovies AS (
    SELECT 
        ak.name AS director_name,
        ak.person_id AS director_id,
        at.title AS movie_title,
        at.production_year
    FROM 
        aka_name ak
    JOIN 
        movie_companies mc ON mc.company_id = ak.person_id
    JOIN 
        aka_title at ON mc.movie_id = at.id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        ak.name, ak.person_id, at.title, at.production_year
),
CombinedData AS (
    SELECT 
        a.actor_name,
        a.actor_id,
        d.director_name,
        d.director_id,
        a.movie_title,
        a.production_year,
        a.keywords
    FROM 
        ActorMovies a
    LEFT JOIN 
        DirectorMovies d ON a.movie_title = d.movie_title AND a.production_year = d.production_year
)
SELECT 
    actor_name, 
    actor_id, 
    director_name, 
    director_id,
    movie_title,
    production_year, 
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    CombinedData
ORDER BY 
    production_year DESC, actor_name;
