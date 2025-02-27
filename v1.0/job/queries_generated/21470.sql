WITH ActorMovieCount AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT ka.movie_id) AS total_movies,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY COUNT(DISTINCT ka.movie_id) DESC) AS rank
    FROM 
        cast_info ka
    GROUP BY 
        ka.person_id
), MoviesWithKeywords AS (
    SELECT 
        kt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword kt
    JOIN 
        keyword kw ON kt.keyword_id = kw.id
    GROUP BY 
        kt.movie_id
), MovieDetails AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(CAST(ce.company_name AS TEXT), 'Unknown Company') AS company_name,
        CASE WHEN at.production_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - at.production_year ELSE NULL END AS years_since_release
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_name ce ON mc.company_id = ce.id
    LEFT JOIN 
        MoviesWithKeywords mk ON at.id = mk.movie_id
    WHERE 
        at.production_year >= 2000
), TopActors AS (
    SELECT 
        nam.name AS actor_name,
        amc.total_movies,
        amc.rank
    FROM 
        ActorMovieCount amc
    JOIN 
        aka_name nam ON amc.person_id = nam.person_id
    WHERE 
        amc.rank <= 10 
        AND (SELECT COUNT(*) FROM cast_info ci WHERE ci.person_id = nam.person_id) > 5
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    ta.actor_name,
    md.company_name,
    CASE 
        WHEN md.years_since_release < 5 THEN 'Recent'
        WHEN md.years_since_release BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Old'
    END AS release_category
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    TopActors ta ON ci.person_id = ta.person_id
WHERE 
    md.keywords NOT LIKE '%action%'
    AND (md.company_name IS NULL OR md.company_name LIKE '%Universal%')
ORDER BY 
    md.production_year DESC,
    ta.total_movies DESC
LIMIT 20;
