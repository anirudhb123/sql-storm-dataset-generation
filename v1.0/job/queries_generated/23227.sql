WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS total_movies,
        STRING_AGG(DISTINCT role_type.role, ', ') AS roles,
        AVG(COALESCE(movie_info.rating, 0)) AS avg_rating
    FROM 
        aka_name
    INNER JOIN cast_info ON aka_name.person_id = cast_info.person_id
    LEFT JOIN role_type ON cast_info.role_id = role_type.id
    LEFT JOIN movie_info ON cast_info.movie_id = movie_info.movie_id
    WHERE 
        aka_name.name IS NOT NULL
    GROUP BY 
        aka_name.person_id, aka_name.name
),
MovieKeywords AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    INNER JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
CompanyMovies AS (
    SELECT 
        movie_companies.movie_id,
        company_name.name AS company_name,
        COUNT(DISTINCT company_name.id) AS total_companies
    FROM 
        movie_companies
    INNER JOIN company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_companies.movie_id, company_name.name
),
MoviesWithRank AS (
    SELECT 
        movies.movie_id,
        movies.title,
        movies.production_year,
        coalesce(companies.total_companies, 0) AS num_companies,
        keywords.keywords,
        actors.avg_rating,
        actors.total_movies,
        actors.roles,
        (CASE 
            WHEN actors.avg_rating >= 8 THEN 'Highly Rated'
            WHEN actors.avg_rating >= 5 AND actors.avg_rating < 8 THEN 'Moderately Rated'
            ELSE 'Low Rated'
         END) AS rating_category
    FROM 
        RankedMovies movies
    LEFT JOIN CompanyMovies companies ON movies.movie_id = companies.movie_id
    LEFT JOIN MovieKeywords keywords ON movies.movie_id = keywords.movie_id
    LEFT JOIN ActorRoles actors ON movies.movie_id IN (
        SELECT cast_info.movie_id FROM cast_info WHERE cast_info.person_id = actors.person_id
    )
    WHERE 
        movies.year_rank <= 5 -- Top 5 recent movies per year
)
SELECT 
    movie_id,
    title,
    production_year,
    num_companies,
    keywords,
    avg_rating,
    total_movies,
    roles,
    rating_category
FROM 
    MoviesWithRank
ORDER BY 
    production_year DESC, avg_rating DESC
LIMIT 100;

