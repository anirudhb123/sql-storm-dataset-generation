WITH RECURSIVE MovieCastCTE AS (
    SELECT 
        c.movie_id, 
        c.person_id, 
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1
    
    UNION ALL
    
    SELECT 
        c.movie_id, 
        c.person_id, 
        mc.level + 1
    FROM 
        cast_info c
    INNER JOIN 
        MovieCastCTE mc ON c.movie_id = mc.movie_id
    WHERE 
        c.nr_order = mc.level + 1
), 
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info cc ON m.id = cc.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
),
CastRanking AS (
    SELECT 
        mc.movie_id,
        COUNT(*) AS cast_member_count
    FROM 
        movie_cast MC
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_count,
        md.company_names,
        md.keywords,
        cr.cast_member_count,
        ROW_NUMBER() OVER (ORDER BY md.company_count DESC, cr.cast_member_count DESC) AS rank
    FROM 
        MovieDetails md
    JOIN 
        CastRanking cr ON md.movie_id = cr.movie_id
)
SELECT 
    *,
    COALESCE(NULLIF(company_count, 0), 1) AS adjusted_company_count
FROM 
    FinalResults
WHERE 
    rank <= 10;
This SQL query retrieves detailed information about the top 10 movies produced after the year 2000 based on their cast and production companies. It uses recursive CTEs to build a hierarchy of cast members, aggregates company names and keywords associated with each movie, and applies ranking while adjusting for any potential null values in the company count.
