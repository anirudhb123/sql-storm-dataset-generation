WITH NameCount AS (
    SELECT 
        a.name AS aka_name, 
        c.name AS character_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        char_name c ON ci.person_id = c.imdb_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.name, c.name
), 
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    nc.aka_name, 
    nc.character_name,
    md.movie_title,
    md.production_year,
    nc.movie_count,
    nc.keyword_count,
    md.company_count
FROM 
    NameCount nc
JOIN 
    cast_info ci ON nc.character_name = (SELECT c.name FROM char_name c WHERE c.imdb_id = ci.person_id)
JOIN 
    MovieDetails md ON ci.movie_id IN (SELECT movie_id FROM movie_info WHERE movie_id = ci.movie_id)
ORDER BY 
    nc.keyword_count DESC, 
    md.production_year ASC;

