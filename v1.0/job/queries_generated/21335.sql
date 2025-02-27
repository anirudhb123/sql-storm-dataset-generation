WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_member_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS a
    LEFT JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info AS c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL AND 
        a.production_year BETWEEN 1980 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_member_count,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieInfo AS (
    SELECT 
        m.movie_title,
        m.production_year,
        CASE 
            WHEN m.cast_member_count > 10 THEN 'Popular'
            WHEN m.cast_member_count IS NULL THEN 'No Cast Info'
            ELSE 'Niche'
        END AS movie_type,
        COALESCE(m.keywords, 'No Keywords') AS keyword_summary
    FROM 
        FilteredMovies AS m
)
SELECT 
    f.movie_title,
    f.production_year,
    f.movie_type,
    f.keyword_summary,
    COALESCE(i.info, 'No Additional Info') AS additional_info
FROM 
    MovieInfo AS f
LEFT OUTER JOIN 
    movie_info AS i ON f.movie_title = i.info -- simulating a bizarre join to retrieve info with a non-standard condition
WHERE 
    f.movie_type = 'Popular'
    OR (f.movie_type = 'Niche' AND f.keyword_summary LIKE '%' || (SELECT keyword FROM keyword WHERE LENGTH(keyword) = 3 LIMIT 1) || '%') -- bizarre predicate using a correlated subquery
ORDER BY 
    f.production_year DESC,
    f.cast_member_count DESC;
