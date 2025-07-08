
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularTitles AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        (SELECT AVG(total_cast) FROM RankedMovies WHERE production_year = rm.production_year) AS avg_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 10
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    pt.title,
    pt.production_year,
    pt.total_cast,
    pt.avg_cast,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    PopularTitles pt
LEFT JOIN 
    MovieKeywords mk ON pt.title_id = mk.movie_id
WHERE 
    pt.total_cast > pt.avg_cast 
ORDER BY 
    pt.production_year DESC, 
    pt.total_cast DESC;
