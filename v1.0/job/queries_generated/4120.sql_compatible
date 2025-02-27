
WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year >= 2000
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
),
CompanyMovies AS (
    SELECT 
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name
),
KeywordsWithCount AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
SelectedMovies AS (
    SELECT 
        DISTINCT at.title,
        at.production_year,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        COALESCE(c.total_movies, 0) AS company_movies
    FROM 
        aka_title at
    LEFT JOIN 
        KeywordsWithCount k ON at.id = k.movie_id
    LEFT JOIN 
        CompanyMovies c ON at.id IN (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = at.id)
    WHERE 
        at.production_year >= 2010
)
SELECT 
    r.title,
    r.production_year,
    a.actor_name,
    s.keyword_count,
    s.company_movies
FROM 
    RankedTitles r
JOIN 
    ActorMovies a ON a.movie_title = r.title AND a.production_year = r.production_year
JOIN 
    SelectedMovies s ON s.title = r.title AND s.production_year = r.production_year
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title;
