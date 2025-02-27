WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', ct.kind, ')'), ', ') AS full_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ct.id = ci.person_role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
), 
MovieRanks AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM RankedMovies
)
SELECT 
    mr.rank,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.full_cast,
    ct.kind AS company_type,
    mn.name AS director,
    pi.info AS director_info
FROM 
    MovieRanks mr
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mr.movie_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mr.movie_id
LEFT JOIN 
    aka_name mn ON mn.person_id = cc.subject_id
LEFT JOIN 
    person_info pi ON pi.person_id = mn.person_id AND pi.info_type_id = 1 
WHERE 
    mr.rank <= 10
ORDER BY 
    mr.rank;