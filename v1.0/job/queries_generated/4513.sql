WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS has_person_info
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
PopularTitles AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        DENSE_RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.id = mk.movie_id
    WHERE 
        rm.cast_count > 0
)
SELECT 
    pt.movie_title, 
    pt.production_year, 
    pt.cast_count, 
    pt.keywords
FROM 
    PopularTitles pt
WHERE 
    pt.rank <= 10
ORDER BY 
    pt.cast_count DESC;
