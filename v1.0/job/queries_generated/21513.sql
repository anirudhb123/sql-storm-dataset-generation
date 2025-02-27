WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        movie_id,
        AVG(rating) AS avg_rating -- Assuming there's a ratings table related to movies
    FROM 
        ratings_table r -- This table is hypothetical and is assumed to have movie_id and rating columns
    GROUP BY 
        movie_id
    HAVING 
        AVG(rating) > 7 -- Filtering for top-rated movies
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        r.production_year,
        COALESCE(cd.companies, 'No Companies') AS companies,
        tt.avg_rating
    FROM 
        RankedTitles r
    LEFT JOIN 
        CompanyDetails cd ON r.movie_title = cd.movie_id
    LEFT JOIN 
        TopRatedMovies tt ON r.movie_title = tt.movie_id
)

SELECT 
    md.actor_name,
    md.movie_title,
    md.production_year,
    CASE 
        WHEN md.avg_rating IS NULL THEN 'Not Rated'
        WHEN md.avg_rating IS NOT NULL AND md.avg_rating < 5 THEN 'Below Average'
        WHEN md.avg_rating BETWEEN 5 AND 7 THEN 'Average'
        WHEN md.avg_rating > 7 THEN 'Above Average'
    END AS rating_category,
    md.companies
FROM 
    MovieDetails md
WHERE 
    md.rn = 1 -- Get the latest movie for each actor
ORDER BY 
    md.production_year DESC,
    md.actor_name;

-- The query makes use of CTEs to organize the data into meaningful segments, 
-- employs window functions to rank titles, aggregates companies, 
-- and handles evaluation of ratings with nuanced categorization
