WITH MovieStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(t.production_year) AS average_year,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
), 
CompanyStats AS (
    SELECT 
        co.id AS company_id,
        co.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        MAX(mc.note) AS last_note
    FROM 
        company_name co
    LEFT JOIN 
        movie_companies mc ON co.id = mc.company_id
    GROUP BY 
        co.id, co.name
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
)
SELECT 
    ms.actor_name,
    ms.total_movies,
    ms.average_year,
    ms.movies_titles,
    cs.company_name,
    cs.movie_count,
    cs.last_note,
    mi.movie_title,
    mi.keywords
FROM 
    MovieStats ms
FULL OUTER JOIN 
    CompanyStats cs ON ms.total_movies = cs.movie_count
LEFT JOIN 
    MovieInfo mi ON mi.movie_id IN (
        SELECT m.id 
        FROM aka_title m
        JOIN movie_info mi ON m.id = mi.movie_id
        WHERE mi.info_type_id NOT IN (SELECT id FROM info_type WHERE info = 'Deleted')
        AND m.production_year BETWEEN 2010 AND 2020
    )
ORDER BY 
    ms.actor_name NULLS LAST, 
    cs.company_name ASC;
