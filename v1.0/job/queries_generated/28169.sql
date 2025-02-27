WITH Movie_Aggregates AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.id) AS cast_count,
        AVG(p.info) AS avg_person_info,
        MAX(m.info) AS max_movie_info
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), Top_Movies AS (
    SELECT 
        ma.movie_id,
        ma.title,
        ma.production_year,
        ma.keywords,
        ma.cast_count,
        ma.avg_person_info,
        ma.max_movie_info,
        RANK() OVER (ORDER BY ma.cast_count DESC) AS rank_by_cast
    FROM 
        Movie_Aggregates ma
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.cast_count,
    tm.avg_person_info,
    tm.max_movie_info
FROM 
    Top_Movies tm
WHERE 
    tm.rank_by_cast <= 10
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC;
