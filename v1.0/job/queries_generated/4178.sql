WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
DetailedMovieInfo AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        r.role,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS movie_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
)
SELECT 
    d.title,
    d.production_year,
    d.keyword,
    d.role,
    d.company_name,
    CASE 
        WHEN dr.rank IS NOT NULL AND dr.rank <= 5 THEN 'Top Movie'
        ELSE 'Regular Movie' 
    END AS movie_category
FROM 
    DetailedMovieInfo d
LEFT JOIN 
    RankedMovies dr ON d.production_year = dr.production_year AND d.title = dr.title
WHERE 
    d.production_year > 2000
ORDER BY 
    d.production_year DESC, 
    d.title;
