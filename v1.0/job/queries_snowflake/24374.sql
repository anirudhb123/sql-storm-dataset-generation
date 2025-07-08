
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN r.role = 'director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT i.info, ', ') WITHIN GROUP (ORDER BY i.info) AS info_details
    FROM 
        movie_info m
    JOIN info_type i ON m.info_type_id = i.id
    GROUP BY 
        m.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.director_count, 0) AS director_count,
        COALESCE(mi.info_details, 'No Info') AS info_details,
        LISTAGG(DISTINCT mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN CastRoles c ON rm.movie_id = c.movie_id
    LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
    LEFT JOIN MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.year_rank <= 5  
    GROUP BY 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        c.actor_count, 
        c.director_count, 
        mi.info_details
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.director_count,
    f.info_details,
    CASE 
        WHEN f.actor_count > 10 THEN 'Popular'
        WHEN f.director_count > 1 THEN 'Multiple Directors'
        ELSE 'Indie Film'
    END AS film_category,
    NULLIF(f.keywords, '') AS keywords_list
FROM 
    FinalResults f
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
