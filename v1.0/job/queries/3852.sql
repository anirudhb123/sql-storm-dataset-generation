WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_titles
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    GROUP BY a.person_id, a.name
),
MoviesWithGenres AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        k.keyword AS genre
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(actor.total_movies, 0) AS total_actors,
    COALESCE(actor.movies_titles, 'No movies found') AS movies_starring,
    COALESCE(genres.genre, 'No genre') AS genre,
    COALESCE(companies.company_count, 0) AS company_count,
    COALESCE(companies.companies, 'No companies') AS companies_associated
FROM RankedMovies m
LEFT JOIN ActorDetails actor ON m.movie_id = actor.total_movies
LEFT JOIN MoviesWithGenres genres ON m.movie_id = genres.movie_id
LEFT JOIN MovieCompanyDetails companies ON m.movie_id = companies.movie_id
WHERE 
    m.title_rank <= 5 
    AND (m.production_year >= 2000 OR actor.total_movies IS NOT NULL)
ORDER BY m.production_year DESC, m.title;
