WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count 
    FROM 
        RankedMovies 
    WHERE 
        rank_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword 
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieInfo AS (
    SELECT 
        m.title,
        i.info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
),
CombinedInfo AS (
    SELECT 
        mk.title,
        mk.keyword,
        mi.info
    FROM 
        MovieKeywords mk
    FULL OUTER JOIN 
        MovieInfo mi ON mk.title = mi.title
),
FinalOutput AS (
    SELECT 
        title,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT info, '; ') AS infos
    FROM 
        CombinedInfo
    GROUP BY 
        title
)
SELECT 
    COALESCE(title, 'Unknown Title') AS title,
    COALESCE(keywords, 'No Keywords') AS keywords,
    COALESCE(infos, 'No Info Available') AS infos
FROM 
    FinalOutput
ORDER BY 
    title;
