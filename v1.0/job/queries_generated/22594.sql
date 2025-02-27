WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY YEAR(t.production_year) ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(m.keyword_list, 'No keywords') AS keywords,
        COALESCE(cmp.name, 'Unknown Company') AS company_name,
        COALESCE(i.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies m
    LEFT JOIN 
        (SELECT 
             movie_id,
             STRING_AGG(k.keyword, ', ') AS keyword_list
         FROM 
             movie_keyword mk
         JOIN 
             keyword k ON mk.keyword_id = k.id
         GROUP BY 
             movie_id) AS k ON m.movie_id = k.movie_id
    LEFT JOIN 
        (SELECT 
             mc.movie_id,
             cn.name
         FROM 
             movie_companies mc
         JOIN 
             company_name cn ON mc.company_id = cn.id
         WHERE 
             mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')) AS cmp ON m.movie_id = cmp.movie_id
    LEFT JOIN 
        (SELECT 
             mi.movie_id,
             MIN(mi.info) AS info
         FROM 
             movie_info mi
         WHERE 
             mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%budget%')
         GROUP BY 
             mi.movie_id) AS i ON m.movie_id = i.movie_id
)
SELECT 
    d.title,
    d.production_year,
    d.keywords,
    d.company_name,
    d.additional_info,
    CASE 
        WHEN d.keywords IS NULL THEN 'No keywords available'
        WHEN d.company_name IS NULL THEN 'No company information'
        ELSE 'Complete information available'
    END AS information_status,
    COUNT(c.id) AS cast_count,
    SUM(CASE 
            WHEN c.person_role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS valid_roles
FROM 
    MovieDetails d
LEFT JOIN 
    cast_info c ON d.movie_id = c.movie_id
WHERE 
    d.rank_by_cast_size <= 5
GROUP BY 
    d.title, d.production_year, d.keywords, d.company_name, d.additional_info
ORDER BY 
    d.production_year DESC, cast_count DESC
LIMIT 10;
