WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS title_rank,
        COUNT(ci.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        title_rank = 1
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN pv.gender IS NOT NULL THEN pv.gender 
            ELSE 'Unknown' 
        END AS primary_gender
    FROM 
        PopularMovies pm
    LEFT JOIN 
        KeywordCount kc ON pm.movie_id = kc.movie_id
    LEFT JOIN 
        (SELECT 
            c.movie_id,
            n.gender
        FROM 
            cast_info c
        JOIN 
            name n ON c.person_id = n.id 
        WHERE 
            c.nr_order = (SELECT MIN(nr_order) FROM cast_info ci WHERE ci.movie_id = c.movie_id)
        ) pv ON pm.movie_id = pv.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    COALESCE(cn.name, 'No Company') AS production_company
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC
LIMIT 50;
