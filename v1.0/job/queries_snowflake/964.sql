
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        pa.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year) AS rn,
        a.id
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name pa ON c.person_id = pa.person_id AND c.role_id = (SELECT id FROM role_type WHERE role = 'director')
    WHERE 
        a.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'description' THEN mi.info END) AS description,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.production_year,
    rm.title,
    rm.director_name,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.description, 'No description available') AS description,
    COALESCE(mi.rating, 'No rating available') AS rating
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.id = mi.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC;
