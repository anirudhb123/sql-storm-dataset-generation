
WITH KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
PopularActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
DirectorInfo AS (
    SELECT 
        p.id AS director_id,
        p.name AS director_name,
        COUNT(DISTINCT mc.movie_id) AS directed_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        person_info pi ON pi.person_id = mc.movie_id
    JOIN 
        name p ON pi.id = p.imdb_id
    WHERE 
        cn.country_code = 'USA' 
        AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        p.id, p.name
)
SELECT 
    km.movie_id,
    km.movie_title,
    km.keywords,
    pa.actor_name AS main_actor,
    di.director_name AS director
FROM 
    KeywordMovies km
LEFT JOIN 
    PopularActors pa ON km.movie_id = pa.actor_id
LEFT JOIN 
    DirectorInfo di ON km.movie_id = di.director_id
ORDER BY 
    km.movie_title;
