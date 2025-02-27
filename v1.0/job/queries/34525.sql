
WITH RECURSIVE TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL AND ci.note IS NOT NULL THEN 1 ELSE 0 END) AS credited_cast
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, c.kind
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TotalMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.company_type,
        tm.total_cast,
        tm.credited_cast,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
),
RankedMovies AS (
    SELECT 
        tm.*,
        RANK() OVER (PARTITION BY tm.company_type ORDER BY tm.credited_cast DESC) AS rank_within_company
    FROM 
        TotalMovies tm
)
SELECT 
    tm.title,
    tm.company_type,
    tm.total_cast,
    tm.credited_cast,
    tm.keywords,
    CASE 
        WHEN tm.credited_cast IS NULL THEN 'No Cast'
        ELSE 'Cast Available'
    END AS cast_status
FROM 
    RankedMovies tm
WHERE 
    rank_within_company <= 10
ORDER BY 
    tm.company_type, tm.credited_cast DESC;
