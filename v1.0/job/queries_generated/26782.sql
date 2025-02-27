WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title AS m
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    COALESCE(m_i.info, 'No additional info') AS additional_info
FROM 
    RankedMovies AS rm
LEFT JOIN 
    movie_info AS m_i ON rm.movie_id = m_i.movie_id
WHERE 
    m_i.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
ORDER BY 
    rm.cast_count DESC;

This query first ranks movies based on the count of distinct cast members and gathers additional information such as alternative names (aka), keywords, and plot details. It limits results to movies produced after the year 2000, filtering for the top 10 based on the cast count. The additional information section ensures that even if no plot information is available, a default message is returned.
