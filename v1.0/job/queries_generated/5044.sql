WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
MovieGenres AS (
    SELECT 
        t.title AS movie_title,
        kt.kind AS genre
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
),
CompanyDetails AS (
    SELECT 
        t.title AS movie_title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        title t ON mc.movie_id = t.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieActorGenres AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        mg.genre
    FROM 
        RankedMovies rm
    JOIN 
        MovieGenres mg ON rm.movie_title = mg.movie_title
)
SELECT 
    mag.movie_title,
    mag.production_year,
    mag.actor_name,
    STRING_AGG(DISTINCT mag.genre, ', ') AS genres,
    COUNT(DISTINCT cd.company_name) AS company_count
FROM 
    MovieActorGenres mag
LEFT JOIN 
    CompanyDetails cd ON mag.movie_title = cd.movie_title
GROUP BY 
    mag.movie_title, mag.production_year, mag.actor_name
ORDER BY 
    mag.production_year DESC, mag.movie_title;
