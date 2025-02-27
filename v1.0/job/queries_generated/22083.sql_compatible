
WITH RecursiveMovieRank AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ko.kind DESC) AS rank_by_kind
    FROM
        aka_title t
    JOIN 
        kind_type ko ON t.kind_id = ko.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN rank_by_kind <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS rank_group
    FROM 
        RecursiveMovieRank
),
CastSummary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.title,
    t.production_year,
    cs.total_cast,
    cs.cast_names,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    CASE 
        WHEN t.rank_group = 'Top 5' THEN 'This is a classic!'
        ELSE 'Could be better...'
    END AS review,
    COUNT(*) OVER (PARTITION BY t.production_year) AS movies_in_year,
    COUNT(DISTINCT CASE WHEN t.production_year < 2000 THEN t.movie_id END) AS pre_2000_count
FROM 
    TopMovies t
LEFT JOIN 
    CastSummary cs ON t.movie_id = cs.movie_id
LEFT JOIN 
    MovieKeywords mk ON t.movie_id = mk.movie_id
GROUP BY 
    t.movie_id, t.title, t.production_year, cs.total_cast, cs.cast_names, t.rank_group
HAVING 
    COUNT(mk.keyword) > 3 OR t.rank_group = 'Top 5'
ORDER BY 
    t.production_year DESC, t.title;
