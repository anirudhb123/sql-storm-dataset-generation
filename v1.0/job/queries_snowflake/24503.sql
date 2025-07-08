
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_count_rank,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
HighRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count_rank,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank <= 5
),
MovieDetails AS (
    SELECT 
        hm.movie_id,
        hm.title,
        hm.production_year,
        COALESCE(i.info, 'No Info') AS movie_info,
        COALESCE(k.keyword, 'No Keywords') AS movie_keyword
    FROM 
        HighRankedMovies hm
    LEFT JOIN 
        movie_info i ON hm.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN 
        movie_keyword mk ON hm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_info,
    ARRAY_AGG(DISTINCT md.movie_keyword) AS keywords,
    CASE 
        WHEN ARRAY_SIZE(ARRAY_AGG(DISTINCT md.movie_keyword)) IS NULL THEN 'No keywords found'
        ELSE 'Contains keywords'
    END AS keyword_status
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.movie_info
ORDER BY 
    md.production_year DESC, md.title
LIMIT 10 OFFSET 0;
