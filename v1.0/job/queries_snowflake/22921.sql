
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'boxoffice')
    GROUP BY 
        t.id, t.title, t.production_year
),

TitleDetails AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_actors,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info c ON r.title_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON r.title_id = mk.movie_id
    WHERE 
        r.rank = 1
    GROUP BY 
        r.title_id, r.title, r.production_year
)

SELECT 
    td.title,
    td.production_year,
    td.total_actors,
    td.total_keywords,
    CASE 
        WHEN td.total_actors IS NULL THEN 'No Actors Listed'
        WHEN td.total_actors > 10 THEN 'Blockbuster'
        ELSE 'Indie Film'
    END AS film_type,
    LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS actors_list
FROM 
    TitleDetails td
LEFT JOIN 
    cast_info ci ON td.title_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
GROUP BY 
    td.title, td.production_year, td.total_actors, td.total_keywords
HAVING 
    td.production_year IS NOT NULL
ORDER BY 
    td.production_year DESC, 
    td.total_actors DESC
LIMIT 20;
