WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS yearly_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
AllMovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(mk.keywords, 'None') AS keywords,
        CASE 
            WHEN rm.production_year IS NULL THEN 'Unknown Year'
            ELSE 'Year ' || rm.production_year
        END AS year_label
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    amd.movie_id,
    amd.title,
    amd.production_year,
    amd.total_cast,
    amd.keywords,
    amd.year_label,
    COALESCE((
        SELECT 
            COUNT(DISTINCT ci.person_id)
        FROM 
            complete_cast cc
        JOIN 
            cast_info ci ON cc.subject_id = ci.person_id
        WHERE 
            cc.movie_id = amd.movie_id
    ), 0) AS complete_cast_count
FROM 
    AllMovieDetails amd
WHERE 
    (amd.total_cast > 5 OR amd.keywords <> 'None')
    AND amd.year_label LIKE 'Year %'
ORDER BY 
    amd.production_year DESC, 
    amd.total_cast DESC
LIMIT 20;