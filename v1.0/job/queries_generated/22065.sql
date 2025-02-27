WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
),

TopActors AS (
    SELECT 
        a.person_id,
        ak.name,
        AVG(COALESCE(c.nr_order, 0)) AS avg_role_order,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        aka_name ak 
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id 
    LEFT JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        a.person_id, ak.name
    HAVING 
        AVG(COALESCE(c.nr_order, 0)) < 5 
        AND COUNT(DISTINCT ci.movie_id) >= 10
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COALESCE(k.keyword, 'N/A') AS keyword,
        (SELECT GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) 
         FROM cast_info ci 
         JOIN aka_name ak ON ci.person_id = ak.person_id 
         WHERE ci.movie_id = rm.movie_id) AS actors,
        rm.production_year,
        SUM(CASE WHEN mc.company_type_id IS NULL THEN 1 ELSE 0 END) AS unrated_companies_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword k ON rm.movie_id = k.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, k.keyword
),

FinalSelection AS (
    SELECT 
        md.movie_id,
        md.title,
        md.keyword,
        md.actors,
        md.production_year,
        COUNT(DISTINCT ta.person_id) AS actor_count,
        SUM(CASE WHEN md.unrated_companies_count > 0 THEN 1 ELSE 0 END) AS has_unrated_company
    FROM 
        MovieDetails md
    LEFT JOIN 
        TopActors ta ON md.actors LIKE '%' || ta.name || '%'
    WHERE 
        md.production_year > 2000 
        AND md.keyword != 'N/A'
    GROUP BY 
        md.movie_id, md.title, md.keyword, md.actors, md.production_year
    HAVING 
        actor_count > 3 
        AND has_unrated_company = 1
)

SELECT 
    fs.title,
    fs.production_year,
    fs.actor_count,
    fs.keyword
FROM 
    FinalSelection fs
ORDER BY 
    fs.production_year DESC, 
    fs.title ASC;

This SQL query is designed to benchmark performance with a range of complex SQL constructs while accessing a fictional film and actor database schema. It uses CTEs for intermediate result sets, window functions for ranking and aggregating data, outer joins for handling missing relationships, correlated subqueries for extracting related data, and complex filtering and grouping to meet specific conditions. The resulting dataset highlights movies produced after 2000 that have multiple notable actors and at least one company with an undefined type.
