WITH RankedMovies AS (
    SELECT 
        at.title AS MovieTitle,
        at.production_year AS ProductionYear,
        COUNT(ci.id) AS CastCount,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS YearRank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        CastCount
    FROM 
        RankedMovies
    WHERE 
        YearRank <= 5
),
MovieDetails AS (
    SELECT 
        tm.MovieTitle,
        tm.ProductionYear,
        coalesce(ci_person.name, 'Unknown') AS MainActor,
        string_agg(ko.keyword, ', ') AS Keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info c ON c.movie_id = (SELECT id FROM aka_title WHERE title = tm.MovieTitle AND production_year = tm.ProductionYear)
    LEFT JOIN 
        aka_name ci_person ON ci_person.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.MovieTitle AND production_year = tm.ProductionYear)
    LEFT JOIN 
        keyword ko ON ko.id = mk.keyword_id
    GROUP BY 
        tm.MovieTitle, tm.ProductionYear, ci_person.name
)
SELECT 
    md.MovieTitle,
    md.ProductionYear,
    md.MainActor,
    COALESCE(md.Keywords, 'No Keywords') AS MovieKeywords,
    CASE 
        WHEN md.MainActor IS NULL THEN 'No Actor Listed'
        ELSE 'Main Actor Present'
    END AS ActorStatus,
    (SELECT COUNT(DISTINCT movie_id) FROM complete_cast) AS TotalMoviesInDatabase
FROM 
    MovieDetails md
ORDER BY 
    md.ProductionYear DESC, md.CastCount DESC;
