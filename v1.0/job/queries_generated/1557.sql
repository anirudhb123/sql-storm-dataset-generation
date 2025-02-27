WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
RelevantMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast_members,
        mwk.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MoviesWithKeywords mwk ON rm.title = mwk.title AND rm.production_year = mwk.production_year
    WHERE 
        rm.rank_by_cast <= 5
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.num_cast_members, 0) AS cast_members,
    STRING_AGG(DISTINCT COALESCE(mwk.keyword, 'No Keyword') ORDER BY mwk.keyword) AS keywords
FROM 
    RelevantMovies rm
FULL OUTER JOIN 
    aka_name an ON (rm.title LIKE '%' || an.name || '%')
GROUP BY 
    rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, cast_members DESC
LIMIT 10;
