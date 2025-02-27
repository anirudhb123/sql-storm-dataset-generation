WITH NameStatistics AS (
    SELECT 
        a.name AS aka_name,
        c.name AS char_name,
        COALESCE(NULLIF(a.name, ''), 'Unknown') AS normalized_aka_name,
        COALESCE(NULLIF(c.name, ''), 'Unknown') AS normalized_char_name,
        COUNT(DISTINCT m.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        char_name c ON c.imdb_index = a.imdb_index
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
    GROUP BY 
        a.name, c.name
), 
MovieStatistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
FinalStatistics AS (
    SELECT 
        ns.aka_name, 
        ns.char_name,
        ns.movie_count,
        ns.titles,
        ms.movie_id,
        ms.title AS movie_title,
        ms.production_year AS movie_year,
        ms.companies,
        ms.keyword_count
    FROM 
        NameStatistics ns
    LEFT JOIN 
        MovieStatistics ms ON ns.movie_count > 0
    ORDER BY 
        ns.movie_count DESC, ns.aka_name
)
SELECT 
    aka_name, 
    char_name, 
    movie_count, 
    titles, 
    movie_id, 
    movie_title, 
    movie_year, 
    companies, 
    keyword_count
FROM 
    FinalStatistics
LIMIT 100;
