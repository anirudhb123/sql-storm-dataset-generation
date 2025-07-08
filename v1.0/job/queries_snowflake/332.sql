
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank_within_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
Top10Movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        tk.keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COALESCE(cg.kind, 'Unknown Type') AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type cg ON mc.company_type_id = cg.id
    LEFT JOIN 
        TitleKeywords tk ON rm.movie_id = tk.movie_id
    WHERE 
        rm.rank_within_year <= 10
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.keywords,
        COUNT(DISTINCT mc.id) AS total_companies
    FROM 
        Top10Movies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.title, tm.production_year, tm.keywords
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords,
    fr.total_companies,
    (CASE 
        WHEN fr.total_companies > 5 THEN 'Highly Collaborated' 
        WHEN fr.total_companies BETWEEN 3 AND 5 THEN 'Moderately Collaborated' 
        ELSE 'Low Collaboration' 
     END) AS collaboration_level
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.total_companies DESC;
