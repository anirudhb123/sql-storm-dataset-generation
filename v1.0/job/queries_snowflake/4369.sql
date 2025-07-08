
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(mn.name, 'Unknown') AS main_actor,
        r.cast_count,
        COALESCE(k.keyword, 'No Keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info c ON r.title_id = c.movie_id AND c.nr_order = 1
    LEFT JOIN 
        aka_name mn ON c.person_id = mn.person_id
    LEFT JOIN 
        movie_keyword mk ON r.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        r.rn <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.main_actor,
    md.cast_count,
    LISTAGG(DISTINCT md.keywords, ', ') WITHIN GROUP (ORDER BY md.keywords) AS all_keywords
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.main_actor, md.cast_count
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 100;
