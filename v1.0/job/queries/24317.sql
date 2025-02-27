
WITH RankedMovies AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        MAX(CASE WHEN ak.name IS NOT NULL THEN ak.name ELSE 'Unknown' END) AS lead_actor,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id, at.title, at.production_year
),
YearlyMovieStats AS (
    SELECT 
        production_year,
        AVG(cast_count) AS avg_cast,
        SUM(CASE WHEN lead_actor IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_lead,
        SUM(CASE WHEN lead_actor IS NULL THEN 1 ELSE 0 END) AS movies_without_lead
    FROM 
        RankedMovies
    GROUP BY 
        production_year
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.lead_actor,
        rm.cast_count,
        ym.avg_cast,
        ym.movies_with_lead,
        ym.movies_without_lead
    FROM 
        RankedMovies rm
    JOIN 
        YearlyMovieStats ym ON rm.production_year = ym.production_year
    WHERE 
        rm.rank_by_cast <= 5 
)
SELECT 
    tm.production_year,
    tm.title,
    tm.lead_actor,
    tm.cast_count,
    tm.avg_cast,
    tm.movies_with_lead,
    tm.movies_without_lead,
    COALESCE(tm.cast_count > tm.avg_cast, FALSE) AS above_average_cast,
    INITCAP(tm.title) AS formatted_title
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
