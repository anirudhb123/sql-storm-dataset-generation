WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS non_null_roles,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank,
        non_null_roles,
        total_actors
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
    ORDER BY 
        production_year, rank
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
FinalResults AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(m.keywords, 'No Keywords') AS keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COALESCE(ii.info, 'No Info') AS movie_info
    FROM 
        MoviesWithKeywords m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info ii ON m.movie_id = ii.movie_id AND ii.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    WHERE 
        (ii.info IS NOT NULL OR ii.info IS NULL)
    ORDER BY 
        m.production_year DESC;
    
SELECT * FROM FinalResults;
