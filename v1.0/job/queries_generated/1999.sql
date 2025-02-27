WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
), MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(ki.keyword, 'No Keyword') AS keyword,
        COALESCE(i.info, 'No Info') AS additional_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON tm.title = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.additional_info,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT c.person_id) AS lead_actors
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info c ON md.title = c.movie_id
WHERE 
    md.additional_info NOT LIKE '%deleted%'
GROUP BY 
    md.title, md.production_year, md.keyword, md.additional_info
ORDER BY 
    md.production_year DESC, lead_actors DESC;
