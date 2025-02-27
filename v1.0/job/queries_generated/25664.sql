WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_size,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_name,
        keywords,
        actors,
        cast_size,
        info_count,
        RANK() OVER (ORDER BY cast_size DESC, production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.keywords,
    rm.actors,
    rm.cast_size,
    rm.info_count
FROM 
    RankedMovies rm
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.rank
LIMIT 10;

This query first constructs a common table expression (CTE) named `MovieDetails` that gathers essential details about movies, including titles, production years, associated companies, keywords, actor names, cast sizes, and info counts. It uses several joins to gather data from various related tables such as `aka_title`, `movie_companies`, `company_name`, `movie_keyword`, `keyword`, `cast_info`, and `aka_name`.

Then, it creates another CTE called `RankedMovies` where it ranks these movies based on the size of their cast and the production year. Finally, it retrieves the top 10 entries from this ranked list, filtering for movies produced after 2000, selecting relevant columns and ordering by rank.
