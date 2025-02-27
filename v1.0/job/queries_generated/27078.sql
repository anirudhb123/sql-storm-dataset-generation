WITH MovieTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        genres.genre AS genre,
        c.name AS company_name,
        k.keyword AS keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.id
    JOIN 
        (SELECT 
            title_id,
            STRING_AGG(genre, ', ') AS genre
         FROM (
            SELECT 
                mt.movie_id AS title_id,
                gt.kind AS genre
            FROM 
                movie_info mi
            JOIN 
                kind_type gt ON mi.info_type_id = gt.id
            WHERE 
                mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
        ) AS genres
        GROUP BY title_id) genres ON genres.title_id = t.id
    WHERE 
        c.country_code = 'USA'
)

SELECT 
    mt.title,
    mt.production_year,
    mt.genre,
    ARRAY_AGG(DISTINCT mt.keyword) AS keywords,
    ARRAY_AGG(DISTINCT mt.company_name) AS companies,
    STRING_AGG(DISTINCT mt.actor_name, ', ') AS cast
FROM 
    MovieTitles mt
GROUP BY 
    mt.movie_id,
    mt.title,
    mt.production_year,
    mt.genre
ORDER BY 
    mt.production_year DESC,
    mt.title;
