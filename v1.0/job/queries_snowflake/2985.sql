
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        t.id
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year, t.id
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
)
SELECT 
    rm.title, 
    rm.production_year, 
    COALESCE(mk.keywords, 'No keywords') AS keywords, 
    rm.num_cast,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic' 
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent' 
    END AS era,
    (SELECT 
        COUNT(*)
     FROM 
        movie_info mi
     WHERE 
        mi.movie_id = rm.id AND
        mi.info_type_id IN (SELECT id FROM info_type WHERE info='Box Office')) AS box_office_info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.num_cast DESC;
