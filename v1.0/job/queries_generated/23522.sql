WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id
), HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 10  -- Top 10 movies per year by cast size
), TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) >= (SELECT AVG(movie_count) FROM (SELECT COUNT(DISTINCT movie_id) AS movie_count 
                                                                     FROM cast_info GROUP BY person_id) AS sub)  -- Average movie count
), MovieDetails AS (
    SELECT 
        hm.title,
        hm.production_year,
        ta.name AS top_actor,
        ta.movie_count,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT Mc.company_id) AS company_count
    FROM 
        HighCastMovies hm
    LEFT JOIN 
        TopActors ta ON ta.movie_count > 10  -- Only actors who acted in more than 10 movies
    LEFT JOIN 
        movie_company Mc ON hm.movie_id = Mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON hm.movie_id = mk.movie_id
    GROUP BY 
        hm.title, hm.production_year, ta.name, ta.movie_count, mk.keyword
), FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.top_actor,
        md.movie_count,
        md.keyword,
        md.company_count,
        CASE 
            WHEN md.company_count > 5 THEN 'Major Studio'
            WHEN md.company_count BETWEEN 3 AND 5 THEN 'Independent Studio'
            ELSE 'Unknown'
        END AS company_type
    FROM 
        MovieDetails md
)
SELECT 
    *,
    CASE 
        WHEN keyword IS NULL THEN 'No Keywords Available'
        ELSE 'Keywords Present'
    END AS keyword_status
FROM 
    FinalResults
ORDER BY 
    production_year DESC, total_cast DESC;
